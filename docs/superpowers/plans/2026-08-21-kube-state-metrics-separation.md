# Independent kube-state-metrics Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Keep kube-state-metrics installed independently from Prometheus and render exactly one collector-specific scrape path.

**Architecture:** Add a focused `modules/kube-state-metrics` Helm wrapper, disable the bundled kube-prometheus-stack dependency, and preserve the existing Service DNS with `fullnameOverride`. Prometheus mode uses a release-labeled ServiceMonitor; VictoriaMetrics mode lets the existing vmagent child module generate the requested static scrape job and suppress it when an equivalent caller job already exists.

**Tech Stack:** Terraform `~> 1.3`, Helm provider `~> 2.17`, kube-prometheus-stack `75.8.0`, kube-state-metrics `6.1.0`, victoria-metrics-agent `0.19.0`, Terraform native tests.

**User constraint:** Do not run `git add`, commit, worktree, reset, checkout, or any other Git mutation. All edits remain unstaged in the current workspace.

---

## Chunk 1: Contract and failing tests

### Task 1: Extend the active Speckit contract

**Files:**
- Modify: `specs/004-metrics-collector-selection/spec.md`
- Modify: `specs/004-metrics-collector-selection/plan.md`
- Modify: `specs/004-metrics-collector-selection/tasks.md`
- Modify: `specs/004-metrics-collector-selection/contracts/metrics-collector-contract.md`
- Modify: `specs/004-metrics-collector-selection/quickstart.md`

- [x] **Step 1: Add lifecycle requirements**

Record that kube-state-metrics is a separate release, remains installed when `prometheus.enabled = false`, and keeps the default Service target `prometheus-kube-state-metrics.monitoring.svc.cluster.local:8080`.

- [x] **Step 2: Add collector routing requirements**

Record the exact Prometheus `ServiceMonitor` label/endpoint contract and exact vmagent job:

```hcl
{
  job_name    = "kube-state-metrics"
  honor_labels = true
  static_configs = [{
    targets = [local.kube_state_metrics_target]
  }]
}
```

- [x] **Step 3: Add migration and test tasks**

Document the ordered Helm ownership handoff and append unchecked tasks T042–T052 to `tasks.md` in this order: contract update, RED assertions, RED run, standalone wrapper, root lifecycle, Prometheus disablement, vmagent generated job, duplicate suppression, documentation, GREEN verification, and read-only diff review. Each task is complete only when its corresponding assertion or command in this plan succeeds.

### Task 2: Write failing Terraform assertions

**Files:**
- Modify: `tests/metrics-collector-selection/2-assertions.tftest.hcl`

- [x] **Step 1: Add failing Prometheus bundled-dependency assertion**

Extend `prometheus_scrape_flag_is_selector_owned`:

```hcl
assert {
  condition = alltrue([
    try(yamldecode(helm_release.prometheus.values[0]).kubeStateMetrics.enabled == false, false),
    try(yamldecode(helm_release.prometheus.values[2]).kubeStateMetrics.enabled == false, false),
  ])
  error_message = "The Prometheus release must never own kube-state-metrics."
}
```

- [x] **Step 2: Add failing vmagent generated-job assertions**

Extend `vmagent_values_are_selector_owned`, which already passes one caller job named `custom-job`, with:

```hcl
assert {
  condition = try(alltrue([
    length(jsondecode(helm_release.vmagent[0].values[0]).extraScrapeConfigs) == 2,
    jsondecode(helm_release.vmagent[0].values[0]).extraScrapeConfigs[0].job_name == "kube-state-metrics",
    jsondecode(helm_release.vmagent[0].values[0]).extraScrapeConfigs[0].honor_labels == true,
    jsondecode(helm_release.vmagent[0].values[0]).extraScrapeConfigs[0].static_configs[0].targets[0] == "prometheus-kube-state-metrics.monitoring.svc.cluster.local:8080",
    jsondecode(helm_release.vmagent[0].values[0]).extraScrapeConfigs[1].job_name == "custom-job",
  ]), false)
  error_message = "vmagent must prepend the generated kube-state-metrics job and preserve caller jobs."
}
```

Expected RED: the assertion fails with the specified error because the current rendered list contains only `custom-job`.

- [x] **Step 3: Add failing root lifecycle assertions**

Extend `prometheus_first_dual_backend` with:

```hcl
assert {
  condition = try(alltrue([
    output.metrics_collector_status.kube_state_metrics_installed,
    output.metrics_collector_status.kube_state_metrics_prometheus_monitor_enabled,
    output.metrics_collector_status.kube_state_metrics_chart_version == "6.1.0",
    output.metrics_collector_status.kube_state_metrics_service_target == "prometheus-kube-state-metrics.monitoring.svc.cluster.local:8080",
  ]), false)
  error_message = "Prometheus mode must keep the independent exporter and enable its ServiceMonitor."
}
```

Extend `victoria_metrics_only_is_supported`, where `prometheus.enabled = false`, with:

```hcl
assert {
  condition = try(alltrue([
    output.metrics_collector_status.kube_state_metrics_installed,
    !output.metrics_collector_status.kube_state_metrics_prometheus_monitor_enabled,
    output.metrics_collector_status.kube_state_metrics_service_target == "prometheus-kube-state-metrics.monitoring.svc.cluster.local:8080",
  ]), false)
  error_message = "VictoriaMetrics-only mode must retain kube-state-metrics without a ServiceMonitor."
}
```

Expected RED: both assertions fail with their specified messages; `try(..., false)` converts missing output attributes into assertion failures instead of evaluation errors. Prometheus-mode absence of vmagent remains covered by the existing `!victoria_metrics_agent_enabled` assertion. Exact standalone Helm/ServiceMonitor fields are verified after the module exists with the Terraform and Helm checks in Chunk 2.

- [x] **Step 4: Run RED verification**

Run:

```bash
terraform -chdir=tests/metrics-collector-selection init -backend=false
terraform -chdir=tests/metrics-collector-selection test
```

Prerequisite: `terraform version` must report Terraform `>= 1.7, < 2.0`; the fixture pins Helm `~> 2.17` and uses `mock_provider "helm" {}`. Expected: the four new assertion messages above appear because the Prometheus chart still owns kube-state-metrics, vmagent has no generated job, and root status has no independent exporter fields. Provider download, initialization, syntax, or missing-module errors are setup failures and do not count as the RED checkpoint.

## Chunk 2: Minimal implementation and verification

### Task 3: Add the independent kube-state-metrics wrapper

**Files:**
- Create: `modules/kube-state-metrics/main.tf`
- Create: `modules/kube-state-metrics/variables.tf`
- Create: `modules/kube-state-metrics/outputs.tf`
- Create: `modules/kube-state-metrics/versions.tf`
- Create: `modules/kube-state-metrics/README.md`

- [x] **Step 1: Define the narrow child-module interface**

Add inputs for namespace creation, chart/release versioning, `fullname_override`, Prometheus monitor activation/release label, and raw `extra_configs`.

- [x] **Step 2: Render selector-owned values last**

Create `helm_release.kube_state_metrics` using chart `kube-state-metrics`. Its final values layer must enforce:

```hcl
{
  fullnameOverride = var.fullname_override
  service = {
    port = 8080
  }
  prometheus = {
    monitor = {
      enabled = var.prometheus_monitor_enabled
      additionalLabels = {
        release = var.prometheus_release_name
      }
      selectorOverride = {
        "app.kubernetes.io/name"     = "kube-state-metrics"
        "app.kubernetes.io/instance" = var.release_name
      }
      http = {
        honorLabels = true
      }
    }
  }
}
```

Use exactly two Helm value layers in this order:

```hcl
values = [
  jsonencode(var.extra_configs),
  jsonencode(local.selector_owned_values),
]
```

The second layer is authoritative, so raw values cannot change the fullname, port, monitor activation, release label, selector, or honor-label behavior. Chart `6.1.0` renders the primary ServiceMonitor endpoint as `port: http`; the pinned chart manifest check in Task 6 verifies that chart contract.

- [x] **Step 3: Export stable metadata**

Output Helm metadata and the derived Service target.

### Task 4: Wire independent lifecycle at the root

**Files:**
- Modify: `variables.tf`
- Modify: `locals.tf`
- Modify: `main.tf`
- Modify: `outputs.tf`

- [x] **Step 1: Add grouped root configuration**

Add `kube_state_metrics` with optional defaults: enabled `true`, chart `6.1.0`, release `kube-state-metrics`, nullable namespace/fullname override, create namespace `true`, and empty `extra_configs`.

- [x] **Step 2: Derive stable names and collector state**

Resolve namespace from `kube_state_metrics.namespace`, then `prometheus.namespace`, then root `namespace`. Resolve fullname to `<prometheus.release_name>-kube-state-metrics` unless overridden, and derive `<fullname>.<namespace>.svc.cluster.local:8080`.

- [x] **Step 3: Create the root child module independently**

Create `module.kube_state_metrics` from `kube_state_metrics.enabled`, not from `prometheus.enabled`. Add the literal block-level dependency `depends_on = [module.prometheus]` so the old subchart is removed before the new release creates preserved resource names. Do not set Helm `force_update`, `replace`, or ownership annotations; stale resources must produce a visible Helm failure.

- [x] **Step 4: Expose resolved status**

Extend `metrics_collector_status` with installed, Service target, and Prometheus monitor activation fields.

### Task 5: Make collector scrape paths exclusive

**Files:**
- Modify: `modules/prometheus/main.tf`
- Modify: `modules/prometheus/values/prometheus-values.yaml.tpl`
- Modify: `modules/victoria-metrics/variables.tf`
- Modify: `modules/victoria-metrics/locals.tf`
- Modify: `modules/victoria-metrics/main.tf`
- Modify: `main.tf`

- [x] **Step 1: Disable bundled kube-state-metrics authoritatively**

Set `kubeStateMetrics.enabled = false` in the Prometheus template and final Helm values layer so raw `extra_configs` cannot re-enable it.

- [x] **Step 2: Add vmagent kube-state-metrics inputs**

Add child inputs for exporter enabled state and the complete kube-state-metrics target. The target defaults to `prometheus-kube-state-metrics.monitoring.svc.cluster.local:8080` for direct child-module compatibility. The root module passes `local.kube_state_metrics_service_target`, which already contains the independently resolved exporter namespace; the VictoriaMetrics child must not derive it from the vmagent namespace.

- [x] **Step 3: Generate or preserve exactly one job**

If vmagent is active, the exporter is enabled, and no caller job has `job_name = "kube-state-metrics"`, prepend the generated job. If a caller already supplies that job name, retain it and suppress the default. Preserve all other caller jobs.

- [x] **Step 4: Pass root-derived values**

Pass kube-state-metrics enabled state and the complete root-derived Service target to the VictoriaMetrics child module. Prometheus mode keeps vmagent absent; VictoriaMetrics mode renders the job automatically.

### Task 6: Verify GREEN and documentation

**Files:**
- Modify: `README.md`
- Modify: `modules/prometheus/README.md`
- Modify: `modules/victoria-metrics/README.md`
- Modify: `tests/metrics-collector-selection/README.md`
- Modify: `tests/metrics-collector-selection/2-assertions.tftest.hcl`

- [x] **Step 1: Run focused tests**

Run:

```bash
terraform -chdir=tests/metrics-collector-selection init -backend=false
terraform -chdir=tests/metrics-collector-selection test
```

Expected: exit zero and every run in `2-assertions.tftest.hcl` reports `pass`; no assertion, provider, or evaluation errors remain. Record the actual run/pass count from the fresh output instead of predicting it in advance.

- [x] **Step 2: Add duplicate-suppression regression test**

Add a caller-provided `kube-state-metrics` job with target `custom-kube-state-metrics.example:8080`. Assert that exactly one rendered job has `job_name = "kube-state-metrics"` and that its only target remains `custom-kube-state-metrics.example:8080`; this proves both suppression and caller override preservation. Run the focused test and expect PASS.

- [x] **Step 3: Format and validate**

Run:

```bash
terraform fmt -recursive
terraform fmt -check -recursive
terraform validate
terraform -chdir=tests/metrics-collector-selection validate
```

Expected: every command exits zero.

- [x] **Step 4: Render the Helm contract**

Verify the pinned chart contract with these copy/paste-ready commands:

```bash
helm template kube-state-metrics prometheus-community/kube-state-metrics \
  --version 6.1.0 \
  --namespace monitoring \
  --set fullnameOverride=prometheus-kube-state-metrics \
  --set prometheus.monitor.enabled=true \
  --set prometheus.monitor.additionalLabels.release=prometheus \
  --set prometheus.monitor.selectorOverride.app\\.kubernetes\\.io/name=kube-state-metrics \
  --set prometheus.monitor.selectorOverride.app\\.kubernetes\\.io/instance=kube-state-metrics \
  --set prometheus.monitor.http.honorLabels=true \
  --show-only templates/service.yaml \
  | yq '[.metadata.name, .spec.ports[0].name, .spec.ports[0].port]'
```

Expected: `["prometheus-kube-state-metrics", "http", 8080]`.

```bash
helm template kube-state-metrics prometheus-community/kube-state-metrics \
  --version 6.1.0 \
  --namespace monitoring \
  --set fullnameOverride=prometheus-kube-state-metrics \
  --set prometheus.monitor.enabled=true \
  --set prometheus.monitor.additionalLabels.release=prometheus \
  --set prometheus.monitor.selectorOverride.app\\.kubernetes\\.io/name=kube-state-metrics \
  --set prometheus.monitor.selectorOverride.app\\.kubernetes\\.io/instance=kube-state-metrics \
  --set prometheus.monitor.http.honorLabels=true \
  --show-only templates/servicemonitor.yaml \
  | yq '[.metadata.labels.release, .spec.selector.matchLabels."app.kubernetes.io/name", .spec.selector.matchLabels."app.kubernetes.io/instance", .spec.endpoints[0].port, .spec.endpoints[0].honorLabels]'
```

Expected: `["prometheus", "kube-state-metrics", "kube-state-metrics", "http", true]`.

Focused Terraform runs provide collector exclusivity checks: Prometheus mode must report monitor enabled and vmagent disabled; VictoriaMetrics mode must report monitor disabled and render exactly one generated/caller kube-state-metrics job.

- [x] **Step 5: Update usage and migration documentation**

Document automatic collector-specific behavior, the safe two-apply ownership handoff for existing installations, and that the temporary environment-level vmagent job may be removed after the module upgrade (but duplicate suppression makes the first upgrade safe).

- [x] **Step 6: Review only; do not stage**

Run read-only status/diff checks and leave all files unstaged, as requested by the user. Verify ownership ordering explicitly:

```bash
rg -n -U 'module "kube_state_metrics"[\\s\\S]*depends_on = \\[module\\.prometheus\\]' main.tf
```

Expected: exactly one match containing the standalone module block and dependency. Also inspect `terraform plan` action ordering during deployment; for an existing Prometheus installation, first apply while `prometheus.enabled = true`, verify the standalone release, and only then disable Prometheus in a second apply. A short first-apply scrape gap is accepted; automatic adoption is not.
