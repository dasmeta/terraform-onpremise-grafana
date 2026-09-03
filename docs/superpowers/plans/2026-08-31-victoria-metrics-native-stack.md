# VictoriaMetrics Native Stack Implementation Plan

> **For Codex:** REQUIRED SUB-SKILL: Use `superpowers:executing-plans` to
> execute this plan task by task. Use `superpowers:test-driven-development` for
> every behavior change and `superpowers:verification-before-completion` before
> claiming completion.

**Goal:** Allow this Terraform module to run either Prometheus or
VictoriaMetrics as a complete standalone metrics stack, while preserving a
one-active-collector dual-backend migration path.

**Architecture:** Backend `enabled` flags continue to control installation and
`metrics_collector` controls the sole active scraper/default datasource.
kube-state-metrics and node-exporter are independent Helm releases.
VictoriaMetrics Operator owns official CRDs; a second module-local Helm release
depends on the Operator and owns VMAgent/native scrape instances. VM-only emits
no Prometheus Operator custom resource.

**Tech Stack:** Terraform HCL (`~> 1.3` public runtime), Terraform native tests
(`>= 1.7`), Helm provider `~> 2.17`, Kubernetes Helm charts, VictoriaMetrics
Operator `0.67.2`.

**Safety:** Preserve the dirty worktree. Do not run `git add`, `git commit`,
`git reset`, `git checkout`, `git push`, or create a branch/PR. Do not run a
live Terraform apply. Do not put credentials in configuration, outputs, tests,
documentation, or command output.

---

### Task 1: Turn VM-only into a testable public contract

**Files:**

- Modify: `tests/metrics-collector-selection/0-setup.tf`
- Modify: `tests/metrics-collector-selection/1-example.tf`
- Modify: `tests/metrics-collector-selection/2-root-contract.tftest.hcl`
- Modify: `variables.tf`
- Modify: `locals.tf`
- Modify: `outputs.tf`

**Step 1: Add fixture inputs and output plumbing**

Add fixture variables for `node_exporter_enabled` and native node scrape flags,
pass them into the root module, and continue exposing only
`metrics_collector_status`. Keep all fixture components disabled unless a run
explicitly tests them.

**Step 2: Replace the old expected failure with a failing success test**

Replace `run "victoria_metrics_requires_prometheus_monitor_crds"` with a plan
run equivalent to:

```hcl
run "victoria_metrics_only_is_supported" {
  command = plan

  module {
    source = "../.."
  }

  variables {
    metrics_collector = "victoria_metrics"
    prometheus        = { enabled = false }
    victoria_metrics  = { enabled = true }
    grafana           = { enabled = false }
    tempo             = { enabled = false }
    loki_stack        = { enabled = false }
    alerts = {
      disk_capacity  = { enabled = false }
      rules          = []
      contact_points = null
      notifications  = null
    }
  }

  assert {
    condition = alltrue([
      !output.metrics_collector_status.prometheus_installed,
      output.metrics_collector_status.victoria_metrics_installed,
      !output.metrics_collector_status.prometheus_scraping_enabled,
      output.metrics_collector_status.victoria_metrics_agent_enabled,
      output.metrics_collector_status.victoria_metrics_standalone,
    ])
    error_message = "VictoriaMetrics-only must be a valid standalone mode."
  }
}
```

**Step 3: Run the root contract test and confirm RED**

Run:

```bash
terraform test \
  -test-directory=tests/metrics-collector-selection \
  -filter=tests/metrics-collector-selection/2-root-contract.tftest.hcl
```

Expected: failure from `output.metrics_collector` saying Prometheus CRDs are
still required, or from the new status field not existing.

**Step 4: Add the root public types and derived state**

In `variables.tf`:

- add the typed `node_exporter` object from the feature contract;
- add `kubelet_scrape_enabled`, `cadvisor_scrape_enabled`,
  `resource_scrape_enabled`, and `kubelet_metrics` to
  `victoria_metrics.agent`;
- change `tempo.metrics_generator` to default `{}` and `remote_url` to nullable
  with default `null`.

In `locals.tf`, derive:

```hcl
prometheus_converter_enabled = (
  var.prometheus.enabled && var.victoria_metrics.enabled
)
victoria_metrics_standalone = (
  local.metrics_collector == "victoria_metrics" &&
  var.victoria_metrics.enabled &&
  !var.prometheus.enabled
)
```

In `outputs.tf`, change the selected-backend precondition so the VM side checks
only `var.victoria_metrics.enabled`. Add the two derived status fields.

**Step 5: Re-run and confirm GREEN**

Run the same filtered test. Expected: VM-only root plan succeeds; invalid
selector and disabled selected-backend cases still pass their expected-failure
assertions.

---

### Task 2: Separate official CRD installation from VM resource instances

**Files:**

- Create: `modules/victoria-metrics/charts/resources/Chart.yaml`
- Create: `modules/victoria-metrics/charts/resources/values.yaml`
- Create: `modules/victoria-metrics/charts/resources/templates/resources.yaml`
- Modify: `modules/victoria-metrics/main.tf`
- Modify: `modules/victoria-metrics/locals.tf`
- Modify: `modules/victoria-metrics/variables.tf`
- Modify: `modules/victoria-metrics/outputs.tf`
- Modify: `tests/metrics-collector-selection/3-operator-values.tftest.hcl`

**Step 1: Write failing release-boundary tests**

Add assertions that:

- Operator `extraObjects` is empty;
- Operator CRDs remain `enabled = true`, `plain = true`, upgrade enabled, and
  cleanup disabled;
- a separate Helm release uses the module-local resources chart;
- its rendered object list contains only VM API objects;
- it declares a Terraform dependency on the Operator through resource
  structure (verified by implementation inspection and a release identity
  output suitable for mock-plan assertions).

Also parameterize the expected converter state instead of always expecting it
enabled.

**Step 2: Run the Operator test and confirm RED**

```bash
terraform test \
  -test-directory=tests/metrics-collector-selection \
  -filter=tests/metrics-collector-selection/3-operator-values.tftest.hcl
```

Expected: existing Operator values still contain VMAgent/VMServiceScrape in
`extraObjects`, no second release exists, and converter is always enabled.

**Step 3: Create the local resources chart**

Use this minimal chart contract:

```yaml
# Chart.yaml
apiVersion: v2
name: victoria-metrics-resources
description: Selector-owned VictoriaMetrics custom-resource instances
type: application
version: 0.1.0
```

```yaml
# values.yaml
objects: []
```

Render each value as one YAML document:

```gotemplate
{{- range .Values.objects }}
---
{{ toYaml . }}
{{- end }}
```

**Step 4: Split the Helm releases**

Keep `helm_release.victoria_metrics_operator` responsible for Operator and
official CRDs only. Add:

```hcl
resource "helm_release" "victoria_metrics_resources" {
  name             = "${var.operator_release_name}-resources"
  chart            = "${path.module}/charts/resources"
  namespace        = var.namespace
  create_namespace = false
  timeout          = 600

  values = [jsonencode({ objects = local.operator_objects })]

  depends_on = [helm_release.victoria_metrics_operator]
}
```

Set Operator `extraObjects = []` as a protected value. Output non-sensitive
resource-release identity and object kind/name pairs, not full object specs.

**Step 5: Implement conditional converter values**

Add `prometheus_converter_enabled` input. Resolve protected values as:

```hcl
operator = {
  disable_prometheus_converter = !var.prometheus_converter_enabled
  enable_converter_ownership   = var.prometheus_converter_enabled
}
```

Continue filtering `WATCH_NAMESPACE` and every
`VM_ENABLEDPROMETHEUSCONVERTER*` raw environment entry. Ensure generated chart
self-monitoring uses native VM mode if enabled.

**Step 6: Re-run and confirm GREEN**

Run the filtered Operator test. Expected: official CRD settings are protected,
custom instances are in the dependent release, and VM-only converter values
are disabled.

---

### Task 3: Generate VMAgent and native node discovery

**Files:**

- Modify: `modules/victoria-metrics/locals.tf`
- Modify: `modules/victoria-metrics/variables.tf`
- Modify: `main.tf`
- Modify: `outputs.tf`
- Create: `tests/metrics-collector-selection/5-native-stack.tftest.hcl`

**Step 1: Write failing native object tests**

Test the resources release's decoded `objects` list for exactly one VMAgent and
default VMNodeScrapes named for kubelet and cAdvisor. Assert:

```hcl
apiVersion = "operator.victoriametrics.com/v1beta1"
scheme     = "https"
bearerTokenFile = "/var/run/secrets/kubernetes.io/serviceaccount/token"
tlsConfig.caFile = "/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"
```

Assert paths `/metrics` and `/metrics/cadvisor`, deterministic `job = kubelet`,
node label mapping, the current metric allowlist, and no `/metrics/resource`
object by default. Add a second run enabling the resource path.

Add malicious `agent_extra_configs` selectors and assert they cannot remove
module-generated service, pod, or node discovery.

**Step 2: Run the native stack test and confirm RED**

```bash
terraform test \
  -test-directory=tests/metrics-collector-selection \
  -filter=tests/metrics-collector-selection/5-native-stack.tftest.hcl
```

Expected: VMNodeScrape objects and protected node selectors do not exist.

**Step 3: Extend protected VMAgent selectors**

Protect and set the VMAgent node selectors in addition to existing pod/service
selectors. Keep `selectAllByDefault = true` so module-generated and
application-owned native VM scrape objects remain discoverable across watched
namespaces.

**Step 4: Build native node objects**

Create one shared object builder shape in locals and instantiate it for enabled
paths. Use only file paths for auth. Include metric relabeling equivalent to:

```hcl
metricRelabelConfigs = [{
  source_labels = ["__name__"]
  regex         = format("^(%s)$", join("|", var.agent_kubelet_metrics))
  action        = "keep"
}]
```

Use relabeling to resolve each node's internal address and set the `node`,
`instance`, `metrics_path`, and `job` labels expected by dashboards.

**Step 5: Wire root inputs and status**

Pass all agent flags and the metric allowlist from root `main.tf`. Add boolean
status for `kubelet`, `cadvisor`, and `resource` native scrape activation.

**Step 6: Re-run and confirm GREEN**

Run the filtered native stack test and the root contract test. Expected: only
VM API objects in VM-only, default resource path absent, explicit resource path
present, and no credential value in plans or outputs.

---

### Task 4: Add the independent node-exporter child

**Files:**

- Create: `modules/node-exporter/main.tf`
- Create: `modules/node-exporter/locals.tf`
- Create: `modules/node-exporter/variables.tf`
- Create: `modules/node-exporter/outputs.tf`
- Create: `modules/node-exporter/versions.tf`
- Create: `modules/node-exporter/README.md`
- Modify: `tests/metrics-collector-selection/5-native-stack.tftest.hcl`

**Step 1: Write failing direct child tests**

In the existing native-stack test file, add a run using
`source = "../../modules/node-exporter"`. Assert:

- chart `prometheus-node-exporter` version `4.47.1`;
- stable `fullnameOverride` and service port `metrics`/`9100`;
- current requests/limits;
- `--web.disable-exporter-metrics`;
- service annotation `prometheus.io/scrape = "false"`;
- selected Prometheus ServiceMonitor and `^go_.*` metric drop;
- raw values cannot re-enable annotation scraping or the wrong monitor mode.

**Step 2: Run the direct child test and confirm RED**

Run the native-stack filtered command. Expected: module source is absent.

**Step 3: Create child variables and selector-owned values**

Expose chart/release/namespace/fullname, resources, monitor gate, Prometheus
release label, and raw values. Apply raw values first and final protected values
last in `helm_release.values`.

Preserve current effective resources:

```hcl
requests = { cpu = "100m", memory = "200Mi" }
limits   = { cpu = "200m", memory = "500Mi" }
```

**Step 4: Create release and outputs**

Use the official Prometheus community repository, pinned chart `4.47.1`, and
output only release/service identities and monitor state.

**Step 5: Re-run and confirm GREEN**

Run the direct child test. Expected: values are stable and raw activation
bypasses are closed.

---

### Task 5: Wire shared exporters and disable bundled copies

**Files:**

- Modify: `main.tf`
- Modify: `locals.tf`
- Modify: `outputs.tf`
- Modify: `modules/prometheus/values/prometheus-values.yaml.tpl`
- Modify: `modules/prometheus/locals.tf`
- Modify: `modules/prometheus/main.tf`
- Modify: `modules/victoria-metrics/locals.tf`
- Modify: `modules/victoria-metrics/variables.tf`
- Modify: `tests/metrics-collector-selection/2-root-contract.tftest.hcl`
- Modify: `tests/metrics-collector-selection/3-operator-values.tftest.hcl`
- Modify: `tests/metrics-collector-selection/4-generated-objects.tftest.hcl`

**Step 1: Write failing exporter lifecycle tests**

Add Prometheus-only and VM-only assertions that both exporters remain installed
by default and exactly one discovery boolean per exporter is true. Add disabled
exporter runs that assert both discovery booleans are false.

Extend Prometheus child tests so both raw and final values require:

```hcl
kubeStateMetrics.enabled == false
nodeExporter.enabled     == false
```

**Step 2: Run affected tests and confirm RED**

Run filtered root, Operator, and generated-object files. Expected:
node-exporter is still bundled and no native node-exporter scrape exists.

**Step 3: Instantiate independent node-exporter**

Resolve stable namespace/fullname in root locals. Set monitor booleans exactly
like KSM:

```hcl
node_exporter_prometheus_monitor_enabled = (
  var.node_exporter.enabled &&
  var.prometheus.enabled &&
  local.prometheus_scraping_enabled
)

node_exporter_vm_service_scrape_enabled = (
  var.node_exporter.enabled &&
  var.victoria_metrics.enabled &&
  local.victoria_metrics_agent_enabled
)
```

Make the independent exporter depend on `module.prometheus` so the old bundled
DaemonSet is removed/disabled before the new release assumes ownership.

**Step 4: Force bundled copies off**

Change both template defaults and final selector-owned Prometheus values to
disable kube-state-metrics and node-exporter after caller raw values.

**Step 5: Add native node-exporter VMServiceScrape**

Match stable labels:

```hcl
"app.kubernetes.io/name"     = "prometheus-node-exporter"
"app.kubernetes.io/instance" = var.agent_node_exporter_release_name
```

Use named port `metrics` and the same `^go_.*` drop. Keep KSM caller-job
suppression behavior unchanged; do not fabricate static jobs.

**Step 6: Re-run and confirm GREEN**

Expected: one exporter release each, one selected monitor each, no bundled
copies, and disabled exporters produce no discovery object.

---

### Task 6: Complete dual-backend and datasource selection

**Files:**

- Modify: `locals.tf`
- Modify: `main.tf`
- Modify: `outputs.tf`
- Modify: `modules/grafana/locals.tf`
- Modify: `modules/grafana/variables.tf`
- Modify: `tests/metrics-collector-selection/2-root-contract.tftest.hcl`
- Modify: `tests/metrics-collector-selection/3-operator-values.tftest.hcl`
- Modify: `tests/metrics-collector-selection/5-native-stack.tftest.hcl`

**Step 1: Add failing four-mode matrix tests**

Cover Prom-only, VM-only, dual/Prom, and dual/VM. For every valid mode assert:

```hcl
one([
  status.prometheus_scraping_enabled,
  status.victoria_metrics_agent_enabled,
])
```

Assert converter true only in both dual rows and exactly one default metrics
datasource matching the selector. Compare VictoriaMetrics retention, replicas,
service names, and PVC values between dual selector runs.

**Step 2: Run mode tests and confirm RED**

Expected: converter/default integration and some status fields do not meet the
matrix.

**Step 3: Resolve collection and converter gates centrally**

Keep Prometheus validation remote write only when Prometheus is the active
scraper and VictoriaMetrics storage is installed. Keep VMAgent only in VM
selection. Pass converter enabled whenever both backend releases are installed.

**Step 4: Make datasource integration explicit**

Provision a datasource only for each installed backend and keep the selected
one as the sole default. Pass `default_metrics_datasource_uid` into Grafana so
Tempo traces-to-metrics does not stay hard-coded to `prometheus` in VM-only.

**Step 5: Re-run and confirm GREEN**

Expected: all four modes satisfy one scraper/one default and selector-only
changes leave VM storage values identical.

---

### Task 7: Make Tempo, Loki, and Grafana monitor paths collector-aware

**Files:**

- Modify: `modules/tempo/locals.tf`
- Modify: `modules/tempo/main.tf`
- Modify: `modules/tempo/variables.tf`
- Modify: `modules/tempo/values/tempo-values.yaml.tpl`
- Modify: `modules/loki-stack/locals.tf`
- Modify: `modules/loki-stack/main.tf`
- Modify: `modules/loki-stack/variables.tf`
- Modify: `modules/loki-stack/outputs.tf`
- Modify: `modules/grafana/locals.tf`
- Modify: `modules/grafana/main.tf`
- Modify: `locals.tf`
- Modify: `main.tf`
- Modify: `modules/victoria-metrics/locals.tf`
- Modify: `tests/metrics-collector-selection/5-native-stack.tftest.hcl`

**Step 1: Write failing integration tests**

Add VM-only runs asserting:

- omitted Tempo URL equals derived vminsert write URL;
- explicit Tempo URL remains exact;
- Tempo/Loki requested monitors produce native VMServiceScrapes;
- raw values cannot re-enable their ServiceMonitors or Loki Prometheus rules;
- raw Grafana values cannot enable its ServiceMonitor in VM-only;
- all generated native objects use the VM API group.

**Step 2: Run and confirm RED**

Expected: Tempo defaults to Prometheus, raw component values can create
Prometheus monitors, and native component scrapes are missing.

**Step 3: Protect Tempo values**

Build final Tempo values after raw input. Set ServiceMonitor enabled only when
Prometheus is selected and the caller requested it. Set remote write to:

```hcl
coalesce(
  try(var.tempo.metrics_generator.remote_url, null),
  local.selected_metrics_remote_write_url,
)
```

Use the explicit value unchanged when non-null.

**Step 4: Protect Loki and Grafana values**

After raw Loki values, force `monitoring.serviceMonitor.enabled` to the selected
Prometheus monitor gate and force `monitoring.rules.enabled = false` in VM-only.
After raw Grafana values, force `serviceMonitor.enabled = false` in VM-only.
Preserve unrelated raw component values.

**Step 5: Generate native component service scrapes**

For Tempo, match `app.kubernetes.io/name = tempo` and instance release label;
scrape `tempo-prom-metrics`, adding `jaeger-metrics` only when Tempo query is
enabled. For Loki, mirror the pinned chart's stable labels, `http-metrics`
port, `/metrics`, interval, and relabeling.

**Step 6: Re-run and confirm GREEN**

Expected: VM-only integrations point only to VM backend/discovery while
explicit caller URL and unrelated chart settings remain intact.

---

### Task 8: Harden overrides, outputs, and documentation

**Files:**

- Modify: `outputs.tf`
- Modify: `modules/victoria-metrics/outputs.tf`
- Modify: `modules/node-exporter/outputs.tf`
- Modify: `README.md`
- Modify: `modules/prometheus/README.md`
- Modify: `modules/victoria-metrics/README.md`
- Modify: `modules/node-exporter/README.md`
- Modify: `modules/tempo/README.md`
- Modify: `modules/loki-stack/README.md`
- Modify: `tests/metrics-collector-selection/README.md`

**Step 1: Add final status assertions before output changes**

Ensure tests expect non-sensitive booleans/identities for converter,
standalone state, both exporters, native node paths, module component scrapes,
default datasource, and VM query/write URLs. Assert output does not expose
inline scrape YAML or any key named token/password/secret value.

**Step 2: Run and confirm RED for missing status fields**

Run all focused collector tests. Expected: only the not-yet-exposed status
fields fail.

**Step 3: Complete outputs**

Expose resolved booleans and stable names only. Never return the full native
object list or `inlineScrapeConfig` from root status.

**Step 4: Replace obsolete conversion-only documentation**

Document:

- Prom-only, VM-only, and both dual modes;
- independent exporter behavior;
- clean-cluster CRD/resource release ordering;
- application migration gate for PodMonitor/ServiceMonitor/auth/rules;
- no automatic additional-scrape translation;
- rollback that preserves VM history;
- manual-only old Prometheus CRD cleanup;
- Alertmanager/VMAlert boundary.

Link the feature quickstart from root README.

**Step 5: Re-run focused tests and docs checks**

```bash
terraform test -test-directory=tests/metrics-collector-selection
rg -n "requires both|must remain.*prometheus|conversion mode" README.md modules specs/005-victoria-metrics-native-stack
```

Expected: tests pass; any remaining old wording is either removed or clearly
describes only the dual migration mode.

---

### Task 9: Full verification and handoff

**Files:**

- Verify: all changed feature files

**Step 1: Format production and test HCL**

Run:

```bash
terraform fmt -recursive
terraform fmt -check -recursive
```

Expected: second command exits 0.

**Step 2: Validate root module**

Run:

```bash
terraform validate
```

Expected: `Success! The configuration is valid.`

If provider initialization is missing or network-restricted, report that exact
constraint; do not alter provider versions to bypass it.

**Step 3: Run focused tests**

```bash
terraform test -test-directory=tests/metrics-collector-selection
```

Expected: every run passes with mocked providers and no live infrastructure.

**Step 4: Run available child tests**

Discover first:

```bash
find modules -maxdepth 3 -name '*.tftest.hcl' -print | sort
```

Run each relevant initialized child suite. Preserve and report unrelated
baseline failures rather than changing unrelated modules.

**Step 5: Render/inspect Helm boundaries**

Render the module-local resources chart with representative VM objects and
inspect the pinned upstream chart values. Verify:

- Operator chart owns CRDs and resources chart owns instances;
- VM-only object API versions are all
  `operator.victoriametrics.com/v1beta1`;
- Prometheus-only has no VMAgent/native object;
- both bundled exporters are disabled;
- each independent exporter has one selected monitor path.

Do not use a live cluster apply for this step.

**Step 6: Run final hygiene checks**

```bash
git diff --check
rg -n -i '(bearer_token\s*[:=]\s*[^/$]|api[_-]?token\s*[:=]\s*[^$]|password\s*[:=]\s*[^$])' \
  tests/metrics-collector-selection \
  specs/005-victoria-metrics-native-stack \
  docs/superpowers
```

Review matches manually because documentation may mention field names. Expected:
no credential value and no whitespace error.

**Step 7: Self-review the final diff**

Inspect only; do not stage:

```bash
git status --short
git diff -- variables.tf locals.tf main.tf outputs.tf modules tests/metrics-collector-selection README.md
```

Check every requirement in `specs/005-victoria-metrics-native-stack/spec.md`
against tests and implementation. Confirm unrelated dirty files were not
modified by this feature.

**Step 8: Hand off without Git mutation**

Report:

- files changed;
- supported mode matrix;
- exact test/validation results;
- any baseline limitation;
- application-side migration still required before production Prometheus
  removal;
- no Git staging/commit/push performed.

Do not claim the user's cluster is migrated; module implementation and live
rollout are separate outcomes.

---

## Plan Review Record

- Requirements are traced through
  `specs/005-victoria-metrics-native-stack/tasks.md`.
- Clean-cluster mapping failure is addressed by an explicit Helm release
  dependency, not by private CRD copies or Prometheus CRDs.
- Every behavior task starts with a failing test and includes a narrow command.
- Storage lifecycle, secret handling, dual-scrape prevention, and raw override
  risks have explicit assertions.
- No standard commit checkpoints are included because the user prohibited Git
  mutations.
