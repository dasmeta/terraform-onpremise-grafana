# VictoriaMetrics Operator Collector Support Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the standalone vmagent Helm release with VictoriaMetrics
Operator and an operator-managed VMAgent while preserving one selected scraper,
existing monitor CRs, Secret-backed authorization, kube-state-metrics, and
VictoriaMetrics storage.

**Architecture:** The base module keeps the existing VictoriaMetrics cluster and
installs the official Operator whenever the VM backend is enabled. The Operator
converts application `PodMonitor`/`ServiceMonitor` objects; a VMAgent CR exists
only in Victoria collector mode and writes to the existing vminsert service. The
AWS wrapper mirrors and forwards the revised object without owning resources.

**Tech Stack:** Terraform HCL (`~> 1.3`), Terraform native tests (`>= 1.7`),
Helm provider `~> 2.17`, kube-prometheus-stack `75.8.0`,
victoria-metrics-cluster `0.31.0`, victoria-metrics-operator `0.67.2`,
kube-state-metrics `6.1.0`, Kubernetes CRDs.

---

## Execution rules

- Design source:
  `docs/superpowers/specs/2026-08-20-metrics-collector-selection-design.md`.
- Feature contract:
  `specs/004-metrics-collector-selection/spec.md`.
- Use `@superpowers:test-driven-development` for every behavior change and
  `@terraform-module-developer` for module conventions.
- Preserve unrelated dirty-worktree changes.
- Do not create a worktree and do not run `git add`, `git commit`,
  `git reset`, `git checkout`, or any other git mutation. Commit steps are
  intentionally omitted from this plan at the user's request.
- The AWS wrapper is outside the current writable root. Obtain explicit write
  approval before Task 10; do not work around the filesystem boundary.
- Do not put an application token or Secret value in Terraform, Helm values,
  tests, documentation, command output, or fixtures.

## File responsibility map

| File | Responsibility after this change |
|---|---|
| `variables.tf` | Public selector and nested Operator/VMAgent input contract and validation |
| `locals.tf` | Derived selector state, endpoints, KSM identity, and Prometheus remote-write configuration |
| `main.tf` | Root child-module wiring and Grafana datasource selection |
| `outputs.tf` | Cross-variable preconditions and non-sensitive resolved status |
| `modules/prometheus/main.tf` | Selector-owned Prometheus server and bundled KSM disablement |
| `modules/victoria-metrics/variables.tf` | Narrow child inputs for cluster, Operator, VMAgent, and KSM object |
| `modules/victoria-metrics/locals.tf` | Protected merges and generated VMAgent/VMServiceScrape objects |
| `modules/victoria-metrics/main.tf` | Existing cluster release plus Operator release; no standalone vmagent |
| `modules/victoria-metrics/outputs.tf` | Existing cluster metadata plus a filtered, non-sensitive Operator release identity; never raw Helm metadata/values |
| `modules/kube-state-metrics/*` | Independent exporter and Prometheus ServiceMonitor behavior |
| `tests/metrics-collector-selection/2-root-contract.tftest.hcl` | Root selector, validation, status, datasource, and storage contract tests |
| `tests/metrics-collector-selection/3-operator-values.tftest.hcl` | Child Operator chart/version, precedence, and Prometheus-mode tests |
| `tests/metrics-collector-selection/4-generated-objects.tftest.hcl` | Child VMAgent, VMServiceScrape, inline config, and storage-stability tests |
| `tests/metrics-collector-selection/operator-render-values.yaml` | Non-secret render-only chart fixture with admission webhooks disabled |
| Root/module READMEs | Consumer contract, safety boundaries, rollout, and rollback |
| AWS wrapper `variables.tf`/`main.tf` | Exact schema parity and transparent forwarding |
| AWS wrapper test examples | Prometheus and Victoria collector validation configurations |

## Chunk 1A: Base module contract and failing tests

### Task 0: Prepare the focused fixture and test contract

**Files:**

- Modify: `tests/metrics-collector-selection/0-setup.tf`
- Modify: `tests/metrics-collector-selection/1-example.tf`
- Modify: `tests/metrics-collector-selection/README.md`

- [ ] **Step 1: Add reusable fixture variables**

Add non-secret defaults for `operator_chart_version`,
`operator_release_name`, `agent_name`, and `agent_replica_count`. Keep the
existing selector/backend booleans.

```hcl
variable "operator_chart_version" {
  type    = string
  default = "0.67.2"
}

variable "operator_release_name" {
  type    = string
  default = "victoria-metrics-operator"
}

variable "agent_name" {
  type    = string
  default = "victoria-metrics-agent"
}

variable "agent_replica_count" {
  type    = number
  default = 1
}
```

- [ ] **Step 2: Pass the revised fixture object**

In `1-example.tf`, retain `enabled = var.victoria_metrics_enabled` and add:

```hcl
operator = {
  chart_version = var.operator_chart_version
  release_name  = var.operator_release_name
  extra_configs = {}
}
agent = {
  name                 = var.agent_name
  replica_count        = var.agent_replica_count
  extra_scrape_configs = []
  extra_configs        = {}
}
```

- [ ] **Step 3: Document the runnable fixture contract**

Replace standalone-agent claims in the fixture README with the three split test
file responsibilities and these exact commands:

```sh
cd tests/metrics-collector-selection
terraform init -backend=false -lockfile=readonly
terraform test
```

Expected before implementation: initialization succeeds; tests may be RED only
for behavior intentionally introduced in Tasks 1-6.

### Task 1: Write failing tests for the revised root contract

**Files:**

- Rename/split from: `tests/metrics-collector-selection/2-assertions.tftest.hcl`
- Create: `tests/metrics-collector-selection/2-root-contract.tftest.hcl`
- Create: `tests/metrics-collector-selection/3-operator-values.tftest.hcl`
- Create: `tests/metrics-collector-selection/4-generated-objects.tftest.hcl`
- Modify: `tests/metrics-collector-selection/README.md`

- [ ] **Step 1: Split the tests into independently runnable files**

Move root runs to `2-root-contract`, Operator chart/precedence runs to
`3-operator-values`, and generated-object/storage runs to
`4-generated-objects`. Every `.tftest.hcl` file must begin with its own:

```hcl
mock_provider "helm" {}
```

The root-contract file must additionally declare `mock_provider "grafana" {}`
because its datasource test enables the Grafana child module. Terraform test
files do not share provider mocks. Delete the obsolete combined file after all
runs have been moved.

- [ ] **Step 2: Replace the obsolete VictoriaMetrics-only success case**

Replace `run "victoria_metrics_only_is_supported"` with a plan expected to fail:

```hcl
run "victoria_metrics_requires_prometheus_monitor_crds" {
  command = plan

  module {
    source = "../.."
  }

  variables {
    metrics_collector = "victoria_metrics"
    grafana            = { enabled = false }
    prometheus         = { enabled = false }
    victoria_metrics   = { enabled = true }
    tempo              = { enabled = false }
    loki_stack         = { enabled = false }
    alerts = {
      disk_capacity = { enabled = false }
      rules          = []
      contact_points = null
      notifications  = null
    }
  }

  expect_failures = [output.metrics_collector]
}
```

- [ ] **Step 3: Add invalid VMAgent input tests**

Add separate runs with `agent.name` values `"Invalid_Name"`, `"a..b"`, and
`"a.-b"`. Add replica runs for `0`, `-1`, and `1.5`. Each run uses
`expect_failures = [var.victoria_metrics]`; this proves empty DNS labels and
labels beginning with `-` are rejected as well as obvious invalid names.

- [ ] **Step 4: Tighten both-installed root assertions**

In Prometheus mode, assert Operator installation is reported and VMAgent is not.
In Victoria mode, assert Operator and VMAgent are reported, the native KSM scrape
path is enabled, and Prometheus scraping is disabled.

In the moved `run "prometheus_first_dual_backend"`, change
`grafana.enabled` from false to true; it already enables both metrics backends
and disables unrelated observability components. Assert the Grafana child
output that directly drives `grafana_data_source.this` contains both provisioned
datasource entries and exactly one default:

```hcl
assert {
  condition = alltrue([
    contains(keys(output.grafana.datasources), "Prometheus"),
    contains(keys(output.grafana.datasources), "VictoriaMetrics"),
    output.grafana.datasources["Prometheus"].uid == "prometheus",
    output.grafana.datasources["VictoriaMetrics"].uid == "victoriametrics",
    output.grafana.datasources["Prometheus"].is_default == true,
    output.grafana.datasources["VictoriaMetrics"].is_default == false,
    length([
      for datasource in values(output.grafana.datasources) : datasource
      if try(datasource.is_default, false)
    ]) == 1,
  ])
  error_message = "Both metrics datasources must be provisioned and only Prometheus may be default in Prometheus mode."
}
```

In the moved `run "victoria_metrics_active"`, also change `grafana.enabled`
from false to true and repeat the existence/UID checks with the default booleans
reversed:

```hcl
assert {
  condition = alltrue([
    contains(keys(output.grafana.datasources), "Prometheus"),
    contains(keys(output.grafana.datasources), "VictoriaMetrics"),
    output.grafana.datasources["Prometheus"].is_default == false,
    output.grafana.datasources["VictoriaMetrics"].is_default == true,
    length([
      for datasource in values(output.grafana.datasources) : datasource
      if try(datasource.is_default, false)
    ]) == 1,
    output.metrics_collector_status.default_datasource_uid == "victoriametrics",
  ])
  error_message = "Both metrics datasources must remain provisioned and only VictoriaMetrics may be default in Victoria mode."
}
```

These explicit resource-input assertions fulfill T009/T033 rather than
inferring datasource existence only from the status UID.

- [ ] **Step 5: Run the focused suite and confirm RED**

Run:

```sh
cd tests/metrics-collector-selection
terraform test
```

Expected: FAIL because the current contract still accepts Victoria-only mode,
still exposes `agent.chart_version`/`agent.release_name`, and has no Operator
status fields.

### Task 2: Introduce and wire the revised input schemas atomically

**Files:**

- Modify: `variables.tf`
- Modify: `modules/victoria-metrics/variables.tf`
- Modify: `main.tf`
- Modify: `outputs.tf`

- [ ] **Step 1: Replace the root nested object**

Use this exact public shape:

```hcl
operator = optional(object({
  chart_version = optional(string, "0.67.2")
  release_name  = optional(string, "victoria-metrics-operator")
  extra_configs = optional(any, {})
}), {})
agent = optional(object({
  name                 = optional(string, "victoria-metrics-agent")
  replica_count        = optional(number, 1)
  extra_scrape_configs = optional(any, [])
  extra_configs        = optional(any, {})
}), {})
```

Remove the unpublished standalone fields `agent.chart_version` and
`agent.release_name`.

- [ ] **Step 2: Add root object validation**

Add validation equivalent to:

```hcl
validation {
  condition = (
    length(var.victoria_metrics.agent.name) <= 253 &&
    alltrue([
      for label in split(".", var.victoria_metrics.agent.name) :
      length(label) >= 1 &&
      length(label) <= 63 &&
      can(regex("^[a-z0-9]([-a-z0-9]*[a-z0-9])?$", label))
    ])
  )
  error_message = "victoria_metrics.agent.name must be a valid Kubernetes DNS subdomain name."
}

validation {
  condition = (
    var.victoria_metrics.agent.replica_count >= 1 &&
    floor(var.victoria_metrics.agent.replica_count) ==
    var.victoria_metrics.agent.replica_count
  )
  error_message = "victoria_metrics.agent.replica_count must be a positive integer."
}
```

- [ ] **Step 3: Add the new child inputs without breaking the old resource**

Add the following inputs with descriptions. Temporarily retain
`agent_chart_version`, `agent_release_name`, and
`agent_kube_state_metrics_target` until Task 5 removes the standalone resource;
this keeps every intermediate module configuration valid.

```hcl
variable "operator_chart_version" {
  type        = string
  description = "Pinned VictoriaMetrics Operator Helm chart version."
  default     = "0.67.2"
}

variable "operator_release_name" {
  type        = string
  description = "VictoriaMetrics Operator Helm release name."
  default     = "victoria-metrics-operator"
}

variable "operator_extra_configs" {
  type        = any
  description = "Non-protected VictoriaMetrics Operator chart overrides."
  default     = {}
}

variable "agent_name" {
  type        = string
  description = "Name of the selector-managed VMAgent custom resource."
  default     = "victoria-metrics-agent"
}

variable "agent_kube_state_metrics_namespace" {
  type        = string
  description = "Namespace containing the independent kube-state-metrics Service."
  default     = "monitoring"
}

variable "agent_kube_state_metrics_release_name" {
  type        = string
  description = "Helm instance label of the independent kube-state-metrics Service."
  default     = "kube-state-metrics"
}

variable "agent_kube_state_metrics_fullname" {
  type        = string
  description = "Resolved name of the independent kube-state-metrics Service; the native VMServiceScrape adds a victoria-metrics suffix."
  default     = "prometheus-kube-state-metrics"
}
```

Apply the same label-separated DNS-subdomain validation to `agent_name` and the
same positive-integer validation to the existing `agent_replica_count` child
input. Update existing descriptions so `agent_enabled` means rendering the
VMAgent CR, `agent_extra_scrape_configs` means non-secret
`inlineScrapeConfig`, `agent_extra_configs` means non-protected VMAgent spec
overrides, and `agent_kube_state_metrics_enabled` means rendering the native
KSM `VMServiceScrape` when the remaining gates also pass.

- [ ] **Step 4: Update the root child call in the same change**

Replace obsolete child arguments with:

```hcl
operator_chart_version = var.victoria_metrics.operator.chart_version
operator_release_name  = var.victoria_metrics.operator.release_name
operator_extra_configs = var.victoria_metrics.operator.extra_configs

agent_name                 = var.victoria_metrics.agent.name
agent_replica_count        = var.victoria_metrics.agent.replica_count
agent_extra_scrape_configs = var.victoria_metrics.agent.extra_scrape_configs
agent_extra_configs        = var.victoria_metrics.agent.extra_configs

agent_kube_state_metrics_namespace    = local.kube_state_metrics_namespace
agent_kube_state_metrics_release_name = var.kube_state_metrics.release_name
agent_kube_state_metrics_fullname     = local.kube_state_metrics_fullname
```

Keep the existing `agent_enabled` and
`agent_kube_state_metrics_enabled` arguments. Remove the root call's obsolete
chart/release/static-target arguments; the child retains their declarations only
as a temporary compatibility bridge until Task 5.

Add module-level ordering in the same root call:

```hcl
depends_on = [
  module.prometheus,
  module.kube_state_metrics,
]
```

This ensures a fresh Operator release starts only after kube-prometheus-stack
has supplied Prometheus monitor CRDs and after the independent exporter has
created a custom kube-state-metrics namespace. There is no cycle: both upstream
modules derive their endpoints from input/local values and do not depend on the
VictoriaMetrics module.

- [ ] **Step 5: Implement the CRD-ownership precondition now**

Add this exact condition to the existing output precondition:

```hcl
condition = (
  (
    local.metrics_collector == "prometheus" &&
    var.prometheus.enabled
  ) ||
  (
    local.metrics_collector == "victoria_metrics" &&
    var.victoria_metrics.enabled &&
    var.prometheus.enabled
  )
)
```

The error must state that VictoriaMetrics conversion mode requires
`prometheus.enabled = true` until Prometheus monitor CRDs have independent
ownership. This fulfills foundational task T007 before any Operator resource
work, so
`victoria_metrics_requires_prometheus_monitor_crds` becomes GREEN in this task.

- [ ] **Step 6: Format the changed schema, wiring, and precondition files**

Run:

```sh
terraform fmt variables.tf main.tf outputs.tf modules/victoria-metrics/variables.tf
```

Expected: all four files format successfully.

- [ ] **Step 7: Re-run tests**

Run `terraform test` in `tests/metrics-collector-selection`.

Expected: all invalid name/replica and CRD-ownership tests PASS, including
`a..b` and `a.-b`; only Operator resource/status tests remain RED. Terraform
configuration loading must not fail due to an undeclared child argument.

- [ ] **Step 8: Record the foundational RED-to-GREEN boundary**

Update `tests/metrics-collector-selection/README.md` with the exact command,
the now-GREEN input/CRD-ownership runs, and the named Operator resource/status
runs that remain intentionally RED. Do not claim the full suite passes yet.

## Chunk 1B: Failing Operator, VMAgent, KSM, and storage tests

### Task 3: Write failing child-module tests for Operator values and objects

**Files:**

- Create: `tests/metrics-collector-selection/3-operator-values.tftest.hcl`
- Create: `tests/metrics-collector-selection/4-generated-objects.tftest.hcl`

- [ ] **Step 1: Replace the standalone vmagent selector-owned test**

Create `run "operator_values_are_selector_owned"` with child source
`../../modules/victoria-metrics`. Pass conflicting raw Operator values:

```hcl
operator_extra_configs = {
  operator = {
    disable_prometheus_converter = true
    enable_converter_ownership   = false
  }
  watchNamespaces = ["wrong"]
  extraArgs = {
    "controller.disableReconcileFor" = ["PodMonitor", "ServiceMonitor"]
    "loggerLevel"                    = "WARN"
  }
  env = [
    { name = "WATCH_NAMESPACE", value = "dev" },
    {
      name  = "VM_ENABLEDPROMETHEUSCONVERTER_PODMONITOR"
      value = "false"
    },
    { name = "UNRELATED_OPERATOR_ENV", value = "keep" },
  ]
  envFrom = [{ configMapRef = { name = "unsafe-operator-env" } }]
  rbac = { create = false }
  crds = {
    enabled = false
    cleanup = { enabled = true }
  }
  extraObjects = [{ kind = "WrongObject" }]
}
```

Assert the final values document restores converter enabled, ownership enabled,
top-level `watchNamespaces = []`, RBAC/CRDs enabled, cleanup disabled, and
generated objects. It must override
`extraArgs["controller.disableReconcileFor"]` with an empty list while
preserving the unrelated caller `loggerLevel` argument. It must remove
`WATCH_NAMESPACE` and every `VM_ENABLEDPROMETHEUSCONVERTER*` caller env entry,
preserve `UNRELATED_OPERATOR_ENV`, and force `envFrom = []` because referenced
ConfigMaps/Secrets cannot be inspected safely by Terraform.

Use an executable assertion against the final values document:

```hcl
assert {
  condition = alltrue([
    jsondecode(helm_release.victoria_metrics_operator.values[1]).operator.disable_prometheus_converter == false,
    jsondecode(helm_release.victoria_metrics_operator.values[1]).operator.enable_converter_ownership == true,
    length(jsondecode(helm_release.victoria_metrics_operator.values[1]).watchNamespaces) == 0,
    length(jsondecode(helm_release.victoria_metrics_operator.values[1]).extraArgs["controller.disableReconcileFor"]) == 0,
    jsondecode(helm_release.victoria_metrics_operator.values[1]).extraArgs.loggerLevel == "WARN",
    length([
      for env_var in jsondecode(helm_release.victoria_metrics_operator.values[1]).env : env_var
      if try(env_var.name, "") == "WATCH_NAMESPACE" || can(regex(
        "^VM_ENABLEDPROMETHEUSCONVERTER",
        try(env_var.name, ""),
      ))
    ]) == 0,
    contains(
      [for env_var in jsondecode(helm_release.victoria_metrics_operator.values[1]).env : env_var.name],
      "UNRELATED_OPERATOR_ENV",
    ),
    length(jsondecode(helm_release.victoria_metrics_operator.values[1]).envFrom) == 0,
    jsondecode(helm_release.victoria_metrics_operator.values[1]).rbac.create == true,
    jsondecode(helm_release.victoria_metrics_operator.values[1]).crds.enabled == true,
    jsondecode(helm_release.victoria_metrics_operator.values[1]).crds.cleanup.enabled == false,
    alltrue([
      for object in jsondecode(helm_release.victoria_metrics_operator.values[1]).extraObjects :
      try(object.kind, "") != "WrongObject"
    ]),
  ])
  error_message = "Selector-owned Operator values must close every converter/watch bypass while preserving unrelated explicit settings."
}
```

- [ ] **Step 2: Add a Prometheus-mode Operator test**

With `agent_enabled = false`, assert:

- Operator chart name/version/release are correct.
- `extraObjects` contains no `VMAgent`.
- no native KSM `VMServiceScrape` is present.
- existing VM cluster retention/PVC values remain unchanged.

- [ ] **Step 3: Add a Victoria-mode generated-object test**

With `agent_enabled = true` and no caller jobs, inspect the object selected by
`object.kind == "VMAgent"`. Do not reference an undeclared pseudo-local such as
`vma`; use this executable extraction directly in each assertion (or repeat it
inside a larger expression):

```hcl
one([
  for object in jsondecode(
    helm_release.victoria_metrics_operator.values[1]
  ).extraObjects : object
  if object.kind == "VMAgent"
])
```

Add this complete assertion (the repeated extraction is intentional because a
`.tftest.hcl` file has no shared `local` block):

```hcl
assert {
  condition = alltrue([
    one([
      for object in jsondecode(helm_release.victoria_metrics_operator.values[1]).extraObjects : object
      if try(object.kind, "") == "VMAgent"
    ]).metadata.name == "victoria-metrics-agent",
    one([
      for object in jsondecode(helm_release.victoria_metrics_operator.values[1]).extraObjects : object
      if try(object.kind, "") == "VMAgent"
    ]).metadata.namespace == "monitoring",
    one([
      for object in jsondecode(helm_release.victoria_metrics_operator.values[1]).extraObjects : object
      if try(object.kind, "") == "VMAgent"
    ]).spec.replicaCount == 1,
    one([
      for object in jsondecode(helm_release.victoria_metrics_operator.values[1]).extraObjects : object
      if try(object.kind, "") == "VMAgent"
    ]).spec.selectAllByDefault == true,
    one([
      for object in jsondecode(helm_release.victoria_metrics_operator.values[1]).extraObjects : object
      if try(object.kind, "") == "VMAgent"
    ]).spec.remoteWrite[0].url == "http://victoria-metrics-victoria-metrics-cluster-vminsert.monitoring.svc.cluster.local:8480/insert/0/prometheus/api/v1/write",
    length(yamldecode(one([
      for object in jsondecode(helm_release.victoria_metrics_operator.values[1]).extraObjects : object
      if try(object.kind, "") == "VMAgent"
    ]).spec.inlineScrapeConfig)) == 0,
    one([
      for object in jsondecode(helm_release.victoria_metrics_operator.values[1]).extraObjects : object
      if try(object.kind, "") == "VMAgent"
    ]).spec.resources.requests.cpu == "1",
    one([
      for object in jsondecode(helm_release.victoria_metrics_operator.values[1]).extraObjects : object
      if try(object.kind, "") == "VMAgent"
    ]).spec.resources.requests.memory == "512Mi",
    one([
      for object in jsondecode(helm_release.victoria_metrics_operator.values[1]).extraObjects : object
      if try(object.kind, "") == "VMAgent"
    ]).spec.resources.limits.cpu == "2",
    one([
      for object in jsondecode(helm_release.victoria_metrics_operator.values[1]).extraObjects : object
      if try(object.kind, "") == "VMAgent"
    ]).spec.resources.limits.memory == "1Gi",
    one([
      for object in jsondecode(helm_release.victoria_metrics_operator.values[1]).extraObjects : object
      if try(object.kind, "") == "VMAgent"
    ]).spec.extraArgs["remoteWrite.queues"] == "16",
  ])
  error_message = "Victoria mode must render the exact protected VMAgent defaults."
}
```

In a separate run, pass one non-secret custom scrape job and add this executable
assertion:

```hcl
assert {
  condition = yamldecode(one([
    for object in jsondecode(helm_release.victoria_metrics_operator.values[1]).extraObjects : object
    if try(object.kind, "") == "VMAgent"
  ]).spec.inlineScrapeConfig)[0].job_name == "custom-job"
  error_message = "The supplied non-secret scrape job must be preserved exactly."
}
```

- [ ] **Step 4: Add protected VMAgent override assertions**

Pass this raw spec:

```hcl
agent_extra_configs = {
  replicaCount       = 9
  selectAllByDefault = false
  remoteWrite        = [{ url = "http://wrong-destination" }]
  inlineScrapeConfig = "- job_name: wrong"
  podScrapeSelector              = { matchLabels = { team = "wrong" } }
  podScrapeNamespaceSelector     = { matchNames = ["wrong"] }
  serviceScrapeSelector          = { matchLabels = { team = "wrong" } }
  serviceScrapeNamespaceSelector = { matchNames = ["wrong"] }
}
```

Assert the first four values are replaced by selector-owned values and all four
explicit selector keys are absent from the final VMAgent spec with this complete
assertion:

```hcl
assert {
  condition = alltrue([
    one([
      for object in jsondecode(helm_release.victoria_metrics_operator.values[1]).extraObjects : object
      if try(object.kind, "") == "VMAgent"
    ]).spec.replicaCount == 1,
    one([
      for object in jsondecode(helm_release.victoria_metrics_operator.values[1]).extraObjects : object
      if try(object.kind, "") == "VMAgent"
    ]).spec.selectAllByDefault == true,
    one([
      for object in jsondecode(helm_release.victoria_metrics_operator.values[1]).extraObjects : object
      if try(object.kind, "") == "VMAgent"
    ]).spec.remoteWrite[0].url == "http://victoria-metrics-victoria-metrics-cluster-vminsert.monitoring.svc.cluster.local:8480/insert/0/prometheus/api/v1/write",
    length(yamldecode(one([
      for object in jsondecode(helm_release.victoria_metrics_operator.values[1]).extraObjects : object
      if try(object.kind, "") == "VMAgent"
    ]).spec.inlineScrapeConfig)) == 0,
    !contains(keys(one([
      for object in jsondecode(helm_release.victoria_metrics_operator.values[1]).extraObjects : object
      if try(object.kind, "") == "VMAgent"
    ]).spec), "podScrapeSelector"),
    !contains(keys(one([
      for object in jsondecode(helm_release.victoria_metrics_operator.values[1]).extraObjects : object
      if try(object.kind, "") == "VMAgent"
    ]).spec), "podScrapeNamespaceSelector"),
    !contains(keys(one([
      for object in jsondecode(helm_release.victoria_metrics_operator.values[1]).extraObjects : object
      if try(object.kind, "") == "VMAgent"
    ]).spec), "serviceScrapeSelector"),
    !contains(keys(one([
      for object in jsondecode(helm_release.victoria_metrics_operator.values[1]).extraObjects : object
      if try(object.kind, "") == "VMAgent"
    ]).spec), "serviceScrapeNamespaceSelector"),
  ])
  error_message = "Raw VMAgent selectors must not narrow converted or native scrape discovery."
}
```

This leaves `selectAllByDefault = true` authoritative for converted
PodMonitor/ServiceMonitor objects and native KSM.

- [ ] **Step 5: Rewrite the partial-resource override test**

Move the old run off `helm_release.vmagent` before that resource is deleted.
Pass:

```hcl
agent_extra_configs = {
  resources = {
    requests = { cpu = "1500m" }
    limits   = { memory = "2Gi" }
  }
  extraArgs = {
    "remoteWrite.queues"      = "24"
    "promscrape.maxScrapeSize" = "32MiB"
  }
}
```

Assert the generated VMAgent with executable expressions:

```hcl
assert {
  condition = alltrue([
    one([
      for object in jsondecode(helm_release.victoria_metrics_operator.values[1]).extraObjects : object
      if try(object.kind, "") == "VMAgent"
    ]).spec.resources.requests.cpu == "1500m",
    one([
      for object in jsondecode(helm_release.victoria_metrics_operator.values[1]).extraObjects : object
      if try(object.kind, "") == "VMAgent"
    ]).spec.resources.requests.memory == "512Mi",
    one([
      for object in jsondecode(helm_release.victoria_metrics_operator.values[1]).extraObjects : object
      if try(object.kind, "") == "VMAgent"
    ]).spec.resources.limits.cpu == "2",
    one([
      for object in jsondecode(helm_release.victoria_metrics_operator.values[1]).extraObjects : object
      if try(object.kind, "") == "VMAgent"
    ]).spec.resources.limits.memory == "2Gi",
    one([
      for object in jsondecode(helm_release.victoria_metrics_operator.values[1]).extraObjects : object
      if try(object.kind, "") == "VMAgent"
    ]).spec.extraArgs["remoteWrite.queues"] == "24",
    one([
      for object in jsondecode(helm_release.victoria_metrics_operator.values[1]).extraObjects : object
      if try(object.kind, "") == "VMAgent"
    ]).spec.extraArgs["promscrape.maxScrapeSize"] == "32MiB",
  ])
  error_message = "Partial VMAgent overrides must retain every unspecified default."
}
```

After this rewrite, `4-generated-objects.tftest.hcl` must contain no reference
to `helm_release.vmagent`.

- [ ] **Step 6: Add failing native KSM tests before implementing it**

In `4-generated-objects.tftest.hcl`, use the complete VMAgent extraction from
Steps 3-4 and a filtered list for `VMServiceScrape`. Assert before Task 4:

- Victoria mode has exactly one native KSM object with exact fullname,
  namespace, namespace selector, Service labels, port, honor-label flag, and
  32 MiB endpoint limit;
- Prometheus mode has zero native KSM objects;
- default VMAgent inline YAML has no job named `kube-state-metrics`;
- a caller KSM job produces zero native objects and survives unchanged without
  an injected size limit.

Use this assertion in the default Victoria run:

```hcl
assert {
  condition = alltrue([
    length([
      for object in jsondecode(helm_release.victoria_metrics_operator.values[1]).extraObjects : object
      if try(object.kind, "") == "VMServiceScrape"
    ]) == 1,
    one([
      for object in jsondecode(helm_release.victoria_metrics_operator.values[1]).extraObjects : object
      if try(object.kind, "") == "VMServiceScrape"
    ]).metadata.name == "prometheus-kube-state-metrics-victoria-metrics",
    one([
      for object in jsondecode(helm_release.victoria_metrics_operator.values[1]).extraObjects : object
      if try(object.kind, "") == "VMServiceScrape"
    ]).metadata.namespace == "monitoring",
    one([
      for object in jsondecode(helm_release.victoria_metrics_operator.values[1]).extraObjects : object
      if try(object.kind, "") == "VMServiceScrape"
    ]).spec.namespaceSelector.matchNames == ["monitoring"],
    one([
      for object in jsondecode(helm_release.victoria_metrics_operator.values[1]).extraObjects : object
      if try(object.kind, "") == "VMServiceScrape"
    ]).spec.selector.matchLabels["app.kubernetes.io/name"] == "kube-state-metrics",
    one([
      for object in jsondecode(helm_release.victoria_metrics_operator.values[1]).extraObjects : object
      if try(object.kind, "") == "VMServiceScrape"
    ]).spec.selector.matchLabels["app.kubernetes.io/instance"] == "kube-state-metrics",
    one([
      for object in jsondecode(helm_release.victoria_metrics_operator.values[1]).extraObjects : object
      if try(object.kind, "") == "VMServiceScrape"
    ]).spec.endpoints[0].port == "http",
    one([
      for object in jsondecode(helm_release.victoria_metrics_operator.values[1]).extraObjects : object
      if try(object.kind, "") == "VMServiceScrape"
    ]).spec.endpoints[0].honorLabels == true,
    one([
      for object in jsondecode(helm_release.victoria_metrics_operator.values[1]).extraObjects : object
      if try(object.kind, "") == "VMServiceScrape"
    ]).spec.endpoints[0].max_scrape_size == "32MiB",
    length([
      for scrape_config in yamldecode(one([
        for object in jsondecode(helm_release.victoria_metrics_operator.values[1]).extraObjects : object
        if try(object.kind, "") == "VMAgent"
      ]).spec.inlineScrapeConfig) : scrape_config
      if try(scrape_config.job_name, "") == "kube-state-metrics"
    ]) == 0,
  ])
  error_message = "Victoria mode must render exactly one native KSM object and no static KSM job."
}
```

Add a separate pre-implementation run proving the object follows a non-default
exporter identity rather than accidentally hard-coding the default release:

```hcl
run "custom_kube_state_metrics_identity_is_exact" {
  command = plan

  module {
    source = "../../modules/victoria-metrics"
  }

  variables {
    namespace                               = "metrics-system"
    agent_enabled                           = true
    agent_kube_state_metrics_enabled        = true
    agent_kube_state_metrics_namespace      = "observability"
    agent_kube_state_metrics_release_name   = "state-exporter"
    agent_kube_state_metrics_fullname       = "custom-state-metrics"
  }

  assert {
    condition = alltrue([
      length([
        for object in jsondecode(helm_release.victoria_metrics_operator.values[1]).extraObjects : object
        if try(object.kind, "") == "VMServiceScrape"
      ]) == 1,
      one([
        for object in jsondecode(helm_release.victoria_metrics_operator.values[1]).extraObjects : object
        if try(object.kind, "") == "VMServiceScrape"
      ]).metadata.name == "custom-state-metrics-victoria-metrics",
      one([
        for object in jsondecode(helm_release.victoria_metrics_operator.values[1]).extraObjects : object
        if try(object.kind, "") == "VMServiceScrape"
      ]).metadata.namespace == "observability",
      one([
        for object in jsondecode(helm_release.victoria_metrics_operator.values[1]).extraObjects : object
        if try(object.kind, "") == "VMServiceScrape"
      ]).spec.namespaceSelector.matchNames == ["observability"],
      one([
        for object in jsondecode(helm_release.victoria_metrics_operator.values[1]).extraObjects : object
        if try(object.kind, "") == "VMServiceScrape"
      ]).spec.selector.matchLabels["app.kubernetes.io/name"] == "kube-state-metrics",
      one([
        for object in jsondecode(helm_release.victoria_metrics_operator.values[1]).extraObjects : object
        if try(object.kind, "") == "VMServiceScrape"
      ]).spec.selector.matchLabels["app.kubernetes.io/instance"] == "state-exporter",
      one([
        for object in jsondecode(helm_release.victoria_metrics_operator.values[1]).extraObjects : object
        if try(object.kind, "") == "VMServiceScrape"
      ]).spec.endpoints[0].port == "http",
      one([
        for object in jsondecode(helm_release.victoria_metrics_operator.values[1]).extraObjects : object
        if try(object.kind, "") == "VMServiceScrape"
      ]).spec.endpoints[0].honorLabels == true,
      one([
        for object in jsondecode(helm_release.victoria_metrics_operator.values[1]).extraObjects : object
        if try(object.kind, "") == "VMServiceScrape"
      ]).spec.endpoints[0].max_scrape_size == "32MiB",
    ])
    error_message = "The native KSM object must use the caller's resolved namespace, release label, and fullname."
  }
}
```

This failing run is written before Task 4 and is the custom-identity half of
T023; the default run above is the default-identity half.

In a Prometheus-mode child run, add:

```hcl
assert {
  condition = length([
    for object in jsondecode(helm_release.victoria_metrics_operator.values[1]).extraObjects : object
    if try(object.kind, "") == "VMServiceScrape"
  ]) == 0
  error_message = "Prometheus mode must not render a native KSM object."
}
```

In the caller-job run, pass:

```hcl
agent_extra_scrape_configs = [{
  job_name     = "kube-state-metrics"
  honor_labels = false
  static_configs = [{
    targets = ["custom-kube-state-metrics.example:8080"]
  }]
}]
```

Then add:

```hcl
assert {
  condition = alltrue([
    length([
      for object in jsondecode(helm_release.victoria_metrics_operator.values[1]).extraObjects : object
      if try(object.kind, "") == "VMServiceScrape"
    ]) == 0,
    length(yamldecode(one([
      for object in jsondecode(helm_release.victoria_metrics_operator.values[1]).extraObjects : object
      if try(object.kind, "") == "VMAgent"
    ]).spec.inlineScrapeConfig)) == 1,
    yamldecode(one([
      for object in jsondecode(helm_release.victoria_metrics_operator.values[1]).extraObjects : object
      if try(object.kind, "") == "VMAgent"
    ]).spec.inlineScrapeConfig)[0].static_configs[0].targets == ["custom-kube-state-metrics.example:8080"],
    yamldecode(one([
      for object in jsondecode(helm_release.victoria_metrics_operator.values[1]).extraObjects : object
      if try(object.kind, "") == "VMAgent"
    ]).spec.inlineScrapeConfig)[0].honor_labels == false,
    !contains(keys(yamldecode(one([
      for object in jsondecode(helm_release.victoria_metrics_operator.values[1]).extraObjects : object
      if try(object.kind, "") == "VMAgent"
    ]).spec.inlineScrapeConfig)[0]), "max_scrape_size"),
  ])
  error_message = "A caller-owned KSM job must suppress the native object and remain unchanged."
}
```

- [ ] **Step 7: Add the monitor-conversion boundary test before implementation**

In `3-operator-values.tftest.hcl`, add a Victoria-mode child run with this
non-authenticated application job. The `credentials` label is intentional: it
proves generic source payload keys are preserved and are not treated as Secret
material by name.

```hcl
agent_extra_scrape_configs = [{
  job_name     = "application-non-auth"
  metrics_path = "/metrics"
  static_configs = [{
    targets = ["backend.dev.svc.cluster.local:8000"]
    labels  = { credentials = "business-label" }
  }]
}]
```

Repeat the converter/ownership/top-level-watch assertions from Step 1 and add
this exact VMAgent boundary assertion:

```hcl
assert {
  condition = alltrue([
    one([
      for object in jsondecode(helm_release.victoria_metrics_operator.values[1]).extraObjects : object
      if try(object.kind, "") == "VMAgent"
    ]).spec.inlineScrapeConfig == yamlencode([{
      job_name     = "application-non-auth"
      metrics_path = "/metrics"
      static_configs = [{
        targets = ["backend.dev.svc.cluster.local:8000"]
        labels  = { credentials = "business-label" }
      }]
    }]),
    !contains(keys(yamldecode(one([
      for object in jsondecode(helm_release.victoria_metrics_operator.values[1]).extraObjects : object
      if try(object.kind, "") == "VMAgent"
    ]).spec.inlineScrapeConfig)[0]), "authorization"),
    !contains(keys(yamldecode(one([
      for object in jsondecode(helm_release.victoria_metrics_operator.values[1]).extraObjects : object
      if try(object.kind, "") == "VMAgent"
    ]).spec.inlineScrapeConfig)[0]), "bearer_token"),
  ])
  error_message = "The module must preserve exact non-auth inline jobs and must not fabricate application authorization."
}
```

Also run this source-contract check from the repository root; scan only
variable declarations, not arbitrary monitor payload keys:

```sh
if rg -n -i '^variable "[^"]*(token|secret|credential|authorization)[^"]*"' modules/victoria-metrics/variables.tf; then
  echo "unexpected application credential input on the VictoriaMetrics module boundary" >&2
  exit 1
fi
```

This is the RED test work for T027. Task 7 will only re-run and document it;
it must not introduce this coverage after Tasks 4-6.

- [ ] **Step 8: Add paired storage-identity runs before implementation**

Add these runs to `4-generated-objects.tftest.hcl` before changing collection
resources. Both modes use the same non-default storage identity, and each run
asserts the exact cluster release and PVC-driving values:

```hcl
run "prometheus_mode_preserves_vm_storage_identity" {
  command = plan

  module {
    source = "../../modules/victoria-metrics"
  }

  variables {
    release_name  = "stable-vm"
    agent_enabled = false
    configs = {
      retention_period = "45d"
      vmstorage = {
        replica_count = 4
        storage_class = "gp3"
        storage_size  = "250Gi"
        access_modes  = ["ReadWriteOnce"]
      }
    }
  }

  assert {
    condition = alltrue([
      helm_release.victoria_metrics.name == "stable-vm",
      jsondecode(helm_release.victoria_metrics.values[0]).vmstorage.retentionPeriod == "45d",
      jsondecode(helm_release.victoria_metrics.values[0]).vmstorage.replicaCount == 4,
      jsondecode(helm_release.victoria_metrics.values[0]).vmstorage.persistentVolume.storageClassName == "gp3",
      jsondecode(helm_release.victoria_metrics.values[0]).vmstorage.persistentVolume.size == "250Gi",
      jsondecode(helm_release.victoria_metrics.values[0]).vmstorage.persistentVolume.accessModes == ["ReadWriteOnce"],
    ])
    error_message = "Prometheus mode must retain the requested VictoriaMetrics storage identity."
  }
}

run "victoria_mode_preserves_vm_storage_identity" {
  command = plan

  module {
    source = "../../modules/victoria-metrics"
  }

  variables {
    release_name  = "stable-vm"
    agent_enabled = true
    configs = {
      retention_period = "45d"
      vmstorage = {
        replica_count = 4
        storage_class = "gp3"
        storage_size  = "250Gi"
        access_modes  = ["ReadWriteOnce"]
      }
    }
  }

  assert {
    condition = alltrue([
      helm_release.victoria_metrics.name == "stable-vm",
      jsondecode(helm_release.victoria_metrics.values[0]).vmstorage.retentionPeriod == "45d",
      jsondecode(helm_release.victoria_metrics.values[0]).vmstorage.replicaCount == 4,
      jsondecode(helm_release.victoria_metrics.values[0]).vmstorage.persistentVolume.storageClassName == "gp3",
      jsondecode(helm_release.victoria_metrics.values[0]).vmstorage.persistentVolume.size == "250Gi",
      jsondecode(helm_release.victoria_metrics.values[0]).vmstorage.persistentVolume.accessModes == ["ReadWriteOnce"],
    ])
    error_message = "Victoria mode must retain the same VictoriaMetrics storage identity."
  }
}
```

This is the pre-implementation characterization work for T034. It must exist
before the selector/resource implementation in Tasks 4-6; Task 7 only re-runs
the pair as a regression gate.

- [ ] **Step 9: Run the suite and confirm RED**

```sh
cd tests/metrics-collector-selection
terraform test
```

Expected: FAIL because `helm_release.victoria_metrics_operator` and generated
`extraObjects` do not exist yet.

## Chunk 1C: Protected values, resources, and root wiring

### Task 4: Build protected Operator/VMAgent and native scrape values

**Files:**

- Modify: `modules/victoria-metrics/locals.tf`

- [ ] **Step 1: Retain and inspect caller jobs**

Keep a normalized caller list and duplicate-suppression test:

```hcl
agent_caller_scrape_configs = (
  var.agent_extra_scrape_configs == null
  ? []
  : var.agent_extra_scrape_configs
)

agent_has_kube_state_metrics_scrape_config = try(anytrue([
  for scrape_config in local.agent_caller_scrape_configs :
  try(scrape_config.job_name, "") == "kube-state-metrics"
]), false)
```

- [ ] **Step 2: Preserve nested operational defaults**

Use explicit protected keys and nested merges so a partial override does not
erase sibling defaults:

```hcl
agent_protected_keys = [
  "replicaCount",
  "selectAllByDefault",
  "podScrapeSelector",
  "podScrapeNamespaceSelector",
  "serviceScrapeSelector",
  "serviceScrapeNamespaceSelector",
  "remoteWrite",
  "inlineScrapeConfig",
  "resources",
  "extraArgs",
]

agent_raw_extra_configs = (
  var.agent_extra_configs == null
  ? {}
  : var.agent_extra_configs
)

# Transitional aliases used only by the still-present standalone Helm resource.
# Task 5 deletes these locals together with helm_release.vmagent.
agent_scrape_configs = local.agent_caller_scrape_configs

agent_extra_configs = {
  for key, value in local.agent_raw_extra_configs : key => value
  if !contains([
    "config",
    "remoteWrite",
    "replicaCount",
    "extraScrapeConfigs",
  ], key)
}

agent_unprotected_extra_configs = {
  for key, value in local.agent_raw_extra_configs : key => value
  if !contains(local.agent_protected_keys, key)
}

agent_default_resources = {
  requests = {
    cpu    = "1"
    memory = "512Mi"
  }
  limits = {
    cpu    = "2"
    memory = "1Gi"
  }
}

agent_raw_resource_requests = try(
  local.agent_raw_extra_configs.resources.requests,
  null,
)
agent_raw_resource_limits = try(
  local.agent_raw_extra_configs.resources.limits,
  null,
)
agent_raw_extra_args = try(local.agent_raw_extra_configs.extraArgs, null)

agent_resources = {
  requests = merge(
    local.agent_default_resources.requests,
    local.agent_raw_resource_requests == null
    ? {}
    : local.agent_raw_resource_requests,
  )
  limits = merge(
    local.agent_default_resources.limits,
    local.agent_raw_resource_limits == null
    ? {}
    : local.agent_raw_resource_limits,
  )
}

agent_extra_args = merge(
  { "remoteWrite.queues" = "16" },
  local.agent_raw_extra_args == null ? {} : local.agent_raw_extra_args,
)
```

`agent.extra_configs` is a map-shaped escape hatch. A non-map value is invalid;
do not silently coerce it. `resources` and `extraArgs` are rebuilt from the
explicit nested merges and therefore cannot be reintroduced through the shallow
map. The two compatibility aliases keep the old standalone resource loadable
during Task 4 but no longer inject the generated static KSM job. They are not
part of the new design and must be removed atomically in Task 5.

- [ ] **Step 3: Create the protected VMAgent object**

Generate:

```hcl
agent_object = {
  apiVersion = "operator.victoriametrics.com/v1beta1"
  kind       = "VMAgent"
  metadata = {
    name      = var.agent_name
    namespace = var.namespace
  }
  spec = merge(
    local.agent_unprotected_extra_configs,
    {
      resources = local.agent_resources
      extraArgs = local.agent_extra_args
    },
    {
      replicaCount       = var.agent_replica_count
      selectAllByDefault = true
      remoteWrite        = [{ url = local.agent_remote_write_url }]
      inlineScrapeConfig = yamlencode(local.agent_caller_scrape_configs)
    }
  )
}
```

The final map must own the protected fields.

- [ ] **Step 4: Create the native kube-state-metrics object**

Generate this shape only when VMAgent is enabled, KSM is enabled, and no caller
KSM job exists:

```hcl
agent_kube_state_metrics_object = {
  apiVersion = "operator.victoriametrics.com/v1beta1"
  kind       = "VMServiceScrape"
  metadata = {
    name      = "${var.agent_kube_state_metrics_fullname}-victoria-metrics"
    namespace = var.agent_kube_state_metrics_namespace
  }
  spec = {
    namespaceSelector = {
      matchNames = [var.agent_kube_state_metrics_namespace]
    }
    selector = {
      matchLabels = {
        "app.kubernetes.io/name"     = "kube-state-metrics"
        "app.kubernetes.io/instance" = var.agent_kube_state_metrics_release_name
      }
    }
    endpoints = [{
      port            = "http"
      honorLabels     = true
      max_scrape_size = "32MiB"
    }]
  }
}
```

- [ ] **Step 5: Build the final object list**

Concatenate at most one native KSM object and at most one VMAgent. In Prometheus
mode the list must be empty; converted application objects are reconciled by the
Operator, not listed here.

```hcl
operator_extra_objects = concat(
  (
    var.agent_enabled &&
    var.agent_kube_state_metrics_enabled &&
    !local.agent_has_kube_state_metrics_scrape_config
  ) ? [local.agent_kube_state_metrics_object] : [],
  var.agent_enabled ? [local.agent_object] : [],
)
```

- [ ] **Step 6: Build final protected Operator values**

Normalize the raw chart map and rebuild top-level `extraArgs`. Chart `0.67.2`
uses `controller.disableReconcileFor` to disable Prometheus converters and
merges caller values even when `disable_prometheus_converter = false`; an empty
list causes the chart to emit no disabling flag while preserving unrelated
arguments:

```hcl
operator_raw_extra_configs = (
  var.operator_extra_configs == null
  ? {}
  : var.operator_extra_configs
)

operator_raw_extra_args = try(local.operator_raw_extra_configs.extraArgs, null)

operator_extra_args = merge(
  local.operator_raw_extra_args == null ? {} : local.operator_raw_extra_args,
  { "controller.disableReconcileFor" = [] },
)

operator_raw_env = try(local.operator_raw_extra_configs.env, null)

operator_env = [
  for env_var in (local.operator_raw_env == null ? [] : local.operator_raw_env) : env_var
  if (
    try(env_var.name, "") != "WATCH_NAMESPACE" &&
    !can(regex(
      "^VM_ENABLEDPROMETHEUSCONVERTER",
      try(env_var.name, ""),
    ))
  )
]

operator_selector_owned_values = {
  operator = {
    disable_prometheus_converter = false
    enable_converter_ownership   = true
  }
  watchNamespaces = []
  extraArgs       = local.operator_extra_args
  env             = local.operator_env
  envFrom         = []
  rbac = {
    create = true
  }
  crds = {
    enabled = true
    cleanup = {
      enabled = false
    }
  }
  extraObjects = local.operator_extra_objects
}
```

- [ ] **Step 7: Format and rerun the focused suite**

```sh
terraform fmt modules/victoria-metrics/locals.tf
cd tests/metrics-collector-selection
terraform test
```

Expected: formatting exits 0; generated-object expressions evaluate, but the
suite remains RED only because the Operator Helm release is not wired yet.

### Task 5: Replace standalone vmagent with the Operator Helm release

**Files:**

- Modify: `modules/victoria-metrics/locals.tf`
- Modify: `modules/victoria-metrics/main.tf`
- Modify: `modules/victoria-metrics/outputs.tf`
- Modify: `modules/victoria-metrics/variables.tf`

- [ ] **Step 1: Delete the standalone Helm resource**

Remove the complete `resource "helm_release" "vmagent"` block and, in the same
change, remove the temporary child declarations `agent_chart_version`,
`agent_release_name`, and `agent_kube_state_metrics_target`. Also remove the
Task 4 transition-only locals `agent_scrape_configs` and `agent_extra_configs`;
at that point no resource may reference them. Do not add a `moved` block because
the new Helm release represents a different upstream component and lifecycle.

- [ ] **Step 2: Add the Operator release**

```hcl
resource "helm_release" "victoria_metrics_operator" {
  name             = var.operator_release_name
  repository       = "https://victoriametrics.github.io/helm-charts"
  chart            = "victoria-metrics-operator"
  namespace        = var.namespace
  create_namespace = var.create_namespace
  timeout          = 600
  version          = var.operator_chart_version

  values = [
    jsonencode(var.operator_extra_configs),
    jsonencode(local.operator_selector_owned_values),
  ]

  depends_on = [helm_release.victoria_metrics]
}
```

- [ ] **Step 3: Preserve the two-layer values order**

Verify the release uses raw `operator_extra_configs` first and the Task 4
`operator_selector_owned_values` document second. The second document owns the
converter boolean, owner references, top-level watch, controller-disable key,
RBAC/CRDs/cleanup, and generated objects while preserving unrelated caller
arguments.

- [ ] **Step 4: Expose only a filtered Operator release identity**

Preserve the existing cluster `helm_metadata` output. Never expose
`helm_release.victoria_metrics_operator.metadata`, because Helm metadata can
include rendered values. Add only this derived object:

```hcl
output "operator_release" {
  description = "Non-sensitive identity of the VictoriaMetrics Operator release."
  value = {
    name      = var.operator_release_name
    namespace = var.namespace
    chart     = "victoria-metrics-operator"
    version   = var.operator_chart_version
  }
}
```

- [ ] **Step 5: Run focused tests**

```sh
terraform fmt modules/victoria-metrics/locals.tf modules/victoria-metrics/main.tf modules/victoria-metrics/outputs.tf modules/victoria-metrics/variables.tf
cd tests/metrics-collector-selection
terraform test
```

Expected: formatting exits 0; child Operator and generated-object files report
no failures, including the disabled-controller conflict. Root status/wiring
tests may still fail until Task 6.

### Task 6: Complete selector activation and root status wiring

**Files:**

- Modify: `main.tf`
- Modify: `locals.tf`
- Modify: `outputs.tf`

- [ ] **Step 1: Complete selector-controlled activation in `main.tf`**

Verify the Task 2 arguments are still forwarded and set
`agent_enabled = local.victoria_metrics_agent_enabled`. The child Operator module
must exist whenever `var.victoria_metrics.enabled` is true, while its generated
VMAgent object exists only when the selector chooses VictoriaMetrics.
Keep the Task 2 module-level `depends_on` for both `module.prometheus` and
`module.kube_state_metrics`; do not rely only on the child release's dependency
on the VM cluster.

- [ ] **Step 2: Add derived native-object status in `locals.tf`**

Set the native KSM object active only for Victoria mode with the exporter enabled
and no caller job named `kube-state-metrics`. Keep the Prometheus
ServiceMonitor condition mutually exclusive.

- [ ] **Step 3: Verify the foundational output precondition remains exact**

Use:

```hcl
condition = (
  (
    local.metrics_collector == "prometheus" &&
    var.prometheus.enabled
  ) ||
  (
    local.metrics_collector == "victoria_metrics" &&
    var.victoria_metrics.enabled &&
    var.prometheus.enabled
  )
)
```

Task 2 already implemented this precondition. Keep it unchanged while extending
status. The error must state that VictoriaMetrics conversion mode requires
`prometheus.enabled = true` until Prometheus monitor CRDs have independent
ownership.

- [ ] **Step 4: Extend non-sensitive status output with exact semantics**

Use these exact derived semantics:

```hcl
victoria_metrics_operator_installed = var.victoria_metrics.enabled
victoria_metrics_agent_enabled = (
  local.victoria_metrics_agent_enabled &&
  var.victoria_metrics.enabled
)
victoria_metrics_agent_name = (
  local.victoria_metrics_agent_enabled && var.victoria_metrics.enabled
  ? var.victoria_metrics.agent.name
  : null
)
kube_state_metrics_vm_service_scrape_enabled = (
  var.kube_state_metrics.enabled &&
  var.victoria_metrics.enabled &&
  local.victoria_metrics_agent_enabled &&
  !local.victoria_metrics_agent_has_kube_state_metrics_scrape_config
)
```

Derive `victoria_metrics_agent_has_kube_state_metrics_scrape_config` from the
normalized caller jobs using the same exact-name predicate as the child module.

Do not expose raw Operator values, inline scrape YAML, Secret selectors, or
Secret values.

- [ ] **Step 5: Format and run all base focused tests**

```sh
terraform fmt main.tf locals.tf outputs.tf modules/victoria-metrics
rg -U -P -q '(?s)module "victoria_metrics".{0,3000}?depends_on\s*=\s*\[\s*module\.prometheus,\s*module\.kube_state_metrics,\s*\]' main.tf
cd tests/metrics-collector-selection
terraform test
```

Expected: exit 0 with Terraform reporting `0 failed`; no test file may remain
under the obsolete `2-assertions.tftest.hcl` name, and the source predicate must
prove fresh-install ordering.

## Chunk 2: Scrape-path regression coverage, docs, and render verification

### Task 7: Complete KSM and monitor-conversion regression tests

**Files:**

- Modify: `tests/metrics-collector-selection/3-operator-values.tftest.hcl`
- Modify: `tests/metrics-collector-selection/4-generated-objects.tftest.hcl`
- Modify: `tests/metrics-collector-selection/README.md`

- [ ] **Step 1: Replace static-job assertions**

Remove every assertion against standalone chart `extraScrapeConfigs`. In the
Victoria run, filter `extraObjects` by `kind == "VMServiceScrape"` and assert
the list length is exactly one plus exact metadata name/namespace,
`namespaceSelector.matchNames`, Service labels, endpoint port, `honorLabels`,
and `max_scrape_size`. In the Prometheus run, assert that filtered length is
zero. Decode the default VMAgent `inlineScrapeConfig` and assert it contains no
job named `kube-state-metrics`; this proves the former generated static job is
gone. Re-run both the default and custom namespace/release/fullname identity
runs written in Task 3.

- [ ] **Step 2: Test custom KSM transition-job suppression**

Pass a caller job named `kube-state-metrics`. Assert:

- no generated `VMServiceScrape` exists;
- the VMAgent inline YAML contains exactly the caller job;
- the module does not add `max_scrape_size` to the caller job.

- [ ] **Step 3: Re-run the pre-implementation monitor boundary gate**

Keep and re-run the Task 3 assertions that converter and owner-reference
settings are enabled, top-level
`watchNamespaces` is empty, and the generated VMAgent inline YAML is exactly the
YAML encoding of the supplied non-authenticated caller jobs. Do not blacklist
generic key names such as `credentials`: they are legitimate fields in source
monitor Secret selectors and the module does not render those source monitors.
The Terraform test proves only that this module has no application token input
and generates no application authorization config. Live rollout validation must
prove that the source and converted monitor preserve the same authorization
type and Secret name/key selector without reading the Secret value.

- [ ] **Step 4: Re-run the pre-implementation storage-identity pair**

Re-run the two Task 3 child-module plans with `agent_enabled = false` and true.
Keep their exact assertions for cluster release name, retention, vmstorage
replica count, storage class, size, and access modes. Do not first add these
tests here: this step is only the post-implementation regression gate for T034.

- [ ] **Step 5: Update the fixture README and run tests**

```sh
cd tests/metrics-collector-selection
terraform test
```

Expected: README describes Operator conversion/native KSM object and no longer
claims a standalone agent release or Victoria-only support. Full focused suite
exits 0 and reports `0 failed`.

### Task 8: Update consumer and rollout documentation

**Files:**

- Modify: `README.md`
- Modify: `modules/victoria-metrics/README.md`
- Modify: `modules/prometheus/README.md`
- Modify: `modules/kube-state-metrics/README.md`
- Verify: `specs/004-metrics-collector-selection/quickstart.md`
- Verify: `specs/004-metrics-collector-selection/contracts/metrics-collector-contract.md`

- [ ] **Step 1: Replace standalone-agent examples**

Use `victoria_metrics.operator` and
`victoria_metrics.agent.name/replica_count`. State that both backends remain
enabled for the current conversion mode.

- [ ] **Step 2: Document ownership and override precedence**

Document protected Operator and VMAgent fields, application-owned monitors and
Secrets, generated config Secret runtime behavior, and why inline scrape config
must not contain credentials. Include filtered Operator control env,
`envFrom = []`, and removed Pod/Service selector overrides. State precisely that runtime conversion needs
Secret reads but chart `0.67.2` creates a ClusterRole with cluster-wide wildcard
verbs on `secrets` and `secrets/finalizers`; restrict and audit the Operator
service account plus both source and generated Secrets. Treat narrower custom
RBAC as a separate hardening change.

- [ ] **Step 3: Document the KSM exception**

Explain converted monitors versus the one native `VMServiceScrape`, the scoped
32 MiB limit, and custom transition-job suppression.

- [ ] **Step 4: Document the two-apply rollout and rollback gates**

Include exact queue metrics, bounded overlap/gap semantics, no storage deletion,
and the requirement to verify converted authenticated targets before retiring
Prometheus collection.

- [ ] **Step 5: Search for stale architecture wording**

Run:

```sh
set +e
rg -n 'victoria-metrics-agent.*Helm|agent\.(chart_version|release_name)|VictoriaMetrics-only|static kube-state-metrics' \
  README.md modules tests/metrics-collector-selection \
  --glob '*.md' --glob '*.tf' --glob '*.tftest.hcl'
VMOP_STALE_STATUS=$?
set -e
case "$VMOP_STALE_STATUS" in
  0) exit 1 ;;
  1) ;;
  *) exit "$VMOP_STALE_STATUS" ;;
esac
```

Expected: the complete block exits 0 (the clean `rg` itself exits 1 because it
finds no match). No active source, examples, or consumer documentation describes the
removed architecture. Deliberately exclude `specs/` and `docs/superpowers/`
from this stale-wording gate because those packages may discuss rejected or
historical fields explicitly.

### Task 9: Render and statically verify the pinned chart contract

**Files:**

- Create: `tests/metrics-collector-selection/operator-render-values.yaml`
- Verify/fix only defects exposed in files owned by Tasks 2–8.

- [ ] **Step 1: Validate base Terraform**

```sh
terraform init -backend=false -lockfile=readonly
terraform validate
```

Expected: successful initialization and `Success! The configuration is valid.`

- [ ] **Step 2: Run focused formatting**

```sh
terraform fmt -check variables.tf locals.tf main.tf outputs.tf modules/prometheus modules/victoria-metrics modules/kube-state-metrics tests/metrics-collector-selection
```

Expected: exit 0. Do not use recursive repository formatting to rewrite unrelated
dirty files.

- [ ] **Step 3: Add the non-secret render-only fixture**

Create `operator-render-values.yaml` with the protected production fields and
fixture-equivalent VMAgent/VMServiceScrape objects. Set only
`admissionWebhooks.enabled: false` for this render check so Helm does not emit a
webhook TLS Secret/private key. This fixture override does not change production
module values. It must contain no credentials or Secret objects.

```yaml
admissionWebhooks:
  enabled: false
operator:
  disable_prometheus_converter: false
  enable_converter_ownership: true
watchNamespaces: []
extraArgs:
  controller.disableReconcileFor: []
env:
  - name: UNRELATED_OPERATOR_ENV
    value: keep
envFrom: []
rbac:
  create: true
crds:
  enabled: true
  cleanup:
    enabled: false
extraObjects:
  - apiVersion: operator.victoriametrics.com/v1beta1
    kind: VMAgent
    metadata:
      name: victoria-metrics-agent
      namespace: monitoring
    spec:
      replicaCount: 1
      selectAllByDefault: true
      remoteWrite:
        - url: http://victoria-metrics-victoria-metrics-cluster-vminsert.monitoring.svc.cluster.local:8480/insert/0/prometheus/api/v1/write
      inlineScrapeConfig: "[]\n"
      resources:
        requests: { cpu: "1", memory: 512Mi }
        limits: { cpu: "2", memory: 1Gi }
      extraArgs:
        remoteWrite.queues: "16"
  - apiVersion: operator.victoriametrics.com/v1beta1
    kind: VMServiceScrape
    metadata:
      name: prometheus-kube-state-metrics
      namespace: monitoring
    spec:
      namespaceSelector:
        matchNames: [monitoring]
      selector:
        matchLabels:
          app.kubernetes.io/name: kube-state-metrics
          app.kubernetes.io/instance: kube-state-metrics
      endpoints:
        - port: http
          honorLabels: true
          max_scrape_size: 32MiB
```

- [ ] **Step 4: Render, inspect, and clean up in one fail-fast shell**

Require `yq` v4. Keep creation, checks, and cleanup in one shell so temporary
variables cannot be lost. `set -eu` stops on the first positive predicate
failure, and the `EXIT` trap removes only the validated temporary path even when
Helm or a check fails:

```sh
set -eu
command -v helm >/dev/null
command -v yq >/dev/null
umask 077

VMOP_RENDER_DIR="$(mktemp -d /tmp/vmop-render.XXXXXX)"
VMOP_RENDER_FILE="$VMOP_RENDER_DIR/rendered.yaml"

vmop_cleanup_render() {
  case "$VMOP_RENDER_DIR" in
    /tmp/vmop-render.*) ;;
    *) return 1 ;;
  esac
  if [ -f "$VMOP_RENDER_FILE" ]; then
    rm -f -- "$VMOP_RENDER_FILE"
  fi
  if [ -d "$VMOP_RENDER_DIR" ]; then
    rmdir -- "$VMOP_RENDER_DIR"
  fi
}
trap vmop_cleanup_render EXIT

helm template victoria-metrics-operator \
  oci://ghcr.io/victoriametrics/helm-charts/victoria-metrics-operator \
  --version 0.67.2 \
  --namespace monitoring \
  --include-crds \
  --values tests/metrics-collector-selection/operator-render-values.yaml \
  >"$VMOP_RENDER_FILE"
test -s "$VMOP_RENDER_FILE"
yq eval-all '.' "$VMOP_RENDER_FILE" >/dev/null

yq eval-all -e 'select(.kind == "CustomResourceDefinition" and .metadata.name == "vmagents.operator.victoriametrics.com")' "$VMOP_RENDER_FILE" >/dev/null
yq eval-all -e 'select(.kind == "CustomResourceDefinition" and .metadata.name == "vmservicescrapes.operator.victoriametrics.com")' "$VMOP_RENDER_FILE" >/dev/null
yq eval-all -e 'select(.kind == "ClusterRole") | .rules[] | select(.resources[] == "secrets") | select(.verbs[] == "*")' "$VMOP_RENDER_FILE" >/dev/null
yq eval-all -e 'select(.kind == "VMAgent" and .metadata.name == "victoria-metrics-agent" and .spec.selectAllByDefault == true and .spec.remoteWrite[0].url == "http://victoria-metrics-victoria-metrics-cluster-vminsert.monitoring.svc.cluster.local:8480/insert/0/prometheus/api/v1/write")' "$VMOP_RENDER_FILE" >/dev/null
yq eval-all -e 'select(.kind == "VMServiceScrape" and .metadata.name == "prometheus-kube-state-metrics-victoria-metrics" and .spec.endpoints[0].max_scrape_size == "32MiB")' "$VMOP_RENDER_FILE" >/dev/null
yq eval-all -e '. as $document ireduce (true; . and ($document.kind != "Secret"))' "$VMOP_RENDER_FILE" >/dev/null

set +e
rg -q -- '--controller.disableReconcileFor' "$VMOP_RENDER_FILE"
VMOP_DISABLED_CONTROLLER_STATUS=$?
rg -q 'name: (WATCH_NAMESPACE|VM_ENABLEDPROMETHEUSCONVERTER_(PODMONITOR|SERVICESCRAPE|PROMETHEUSRULE|PROBE|ALERTMANAGERCONFIG|SCRAPECONFIG))' "$VMOP_RENDER_FILE"
VMOP_DISABLED_ENV_STATUS=$?
rg -q 'resource "helm_release" "vmagent"' modules/victoria-metrics --glob '*.tf'
VMOP_STANDALONE_RESOURCE_STATUS=$?
set -e

case "$VMOP_DISABLED_CONTROLLER_STATUS" in
  0) exit 1 ;;
  1) ;;
  *) exit "$VMOP_DISABLED_CONTROLLER_STATUS" ;;
esac
case "$VMOP_DISABLED_ENV_STATUS" in
  0) exit 1 ;;
  1) ;;
  *) exit "$VMOP_DISABLED_ENV_STATUS" ;;
esac
case "$VMOP_STANDALONE_RESOURCE_STATUS" in
  0) exit 1 ;;
  1) ;;
  *) exit "$VMOP_STANDALONE_RESOURCE_STATUS" ;;
esac
```

Expected: the block exits 0 without printing rendered manifests. It proves both
required CRDs render, the chart ClusterRole grants wildcard Secret verbs, no
controller-disable flag, caller watch/converter-disable env, or Secret renders,
and the expected VMAgent/KSM shapes exist. This remains a Helm render-shape check, not CRD schema/admission
validation; only a live apply proves the latter. The source predicate, not Helm
rendering, proves the standalone Terraform release was removed.

- [ ] **Step 5: Run diff hygiene**

```sh
git diff --check
```

Expected: exit 0. This command is read-only; do not stage anything.

## Chunk 3: AWS wrapper parity and final handoff

### Task 10: Create a wrapper contract probe and exact selector examples

**Files:**

- Create:
  `../terraform-aws-grafanav12/tests/metrics-collector-selection/contract.tfvars`
- Modify: `../terraform-aws-grafanav12/tests/base/1-example.tf`
- Modify:
  `../terraform-aws-grafanav12/tests/base-with-victoria-metrics/1-example.tf`

- [ ] **Step 1: Obtain write approval and capture read-only state**

Request filesystem escalation scoped to
`/Users/vazgen/work/Dasmeta/modules/terraform-aws-grafanav12`. Before editing,
run `git status --short` there and preserve all existing dirty changes. Do not
make changes if approval is denied.

- [ ] **Step 2: Add a sentinel contract tfvars file**

```hcl
cluster_name = "wrapper-contract"

victoria_metrics = {
  enabled = true
  operator = {
    chart_version = "0.67.2-wrapper-contract"
    release_name  = "victoria-metrics-operator-contract"
    extra_configs = {}
  }
  agent = {
    name                 = "victoria-metrics-agent-contract"
    replica_count        = 2
    extra_scrape_configs = []
    extra_configs        = {}
  }
}
```

This contains no credential and is used only to prove object conversion at the
wrapper boundary.

- [ ] **Step 3: Run the reliable RED schema probe**

From the wrapper root:

```sh
terraform init -backend=false -lockfile=readonly
printf '%s\n' 'var.victoria_metrics.operator.chart_version' | terraform console -var-file=tests/metrics-collector-selection/contract.tfvars
```

Expected before Task 11: the expression fails with an unsupported/missing
`operator` attribute and does not return the sentinel. Do not use an example's
plain `terraform validate` as the RED proof: Terraform object conversion can
silently discard unknown attributes.

- [ ] **Step 4: Make the Prometheus-first example exact**

Use the same installed backends and input shape as the first rollout apply:

```hcl
metrics_collector = "prometheus"

prometheus = {
  enabled = true
}

victoria_metrics = {
  enabled = true
  operator = {
    chart_version = "0.67.2"
    release_name  = "victoria-metrics-operator"
    extra_configs = {}
  }
  agent = {
    name                 = "victoria-metrics-agent"
    replica_count        = 1
    extra_scrape_configs = []
    extra_configs        = {}
  }
}
```

- [ ] **Step 5: Make the Victoria-selected example exact**

Use the identical `prometheus` and `victoria_metrics` objects from Step 4 and
change only:

```hcl
metrics_collector = "victoria_metrics"
```

### Task 11: Mirror, prove, and document the wrapper input contract

**Files:**

- Modify: `../terraform-aws-grafanav12/variables.tf`
- Verify: `../terraform-aws-grafanav12/main.tf`
- Modify: `../terraform-aws-grafanav12/README.md`
- Modify:
  `../terraform-aws-grafanav12/tests/base-with-victoria-metrics/README.md`
- Modify:
  `../terraform-aws-grafanav12/docs/superpowers/specs/2026-08-20-aws-wrapper-metrics-collector-selection-design.md`
- Modify: `../terraform-aws-grafanav12/specs/003-metrics-collector-selection/spec.md`
- Modify: `../terraform-aws-grafanav12/specs/003-metrics-collector-selection/plan.md`
- Modify: `../terraform-aws-grafanav12/specs/003-metrics-collector-selection/data-model.md`
- Modify: `../terraform-aws-grafanav12/specs/003-metrics-collector-selection/quickstart.md`
- Modify:
  `../terraform-aws-grafanav12/specs/003-metrics-collector-selection/contracts/metrics-collector-wrapper-contract.md`
- Modify: `../terraform-aws-grafanav12/specs/003-metrics-collector-selection/tasks.md`
- Verify/update if needed:
  `../terraform-aws-grafanav12/specs/003-metrics-collector-selection/checklists/requirements.md`

- [ ] **Step 1: Use the exact wrapper variable block**

Preserve all existing cluster fields and replace only the old agent shape with
the following complete variable contract and validations:

```hcl
variable "victoria_metrics" {
  type = object({
    enabled          = optional(bool, false)
    namespace        = optional(string, null)
    create_namespace = optional(bool, true)
    chart_version    = optional(string, "0.31.0")
    release_name     = optional(string, "victoria-metrics")
    retention_period = optional(string, "30d")
    vmstorage = optional(object({
      replica_count = optional(number, 3)
      storage_class = optional(string, "")
      storage_size  = optional(string, "100Gi")
      access_modes  = optional(list(string), ["ReadWriteOnce"])
    }), {})
    vminsert = optional(object({
      replica_count = optional(number, 2)
    }), {})
    vmselect = optional(object({
      replica_count = optional(number, 2)
    }), {})
    operator = optional(object({
      chart_version = optional(string, "0.67.2")
      release_name  = optional(string, "victoria-metrics-operator")
      extra_configs = optional(any, {})
    }), {})
    agent = optional(object({
      name                 = optional(string, "victoria-metrics-agent")
      replica_count        = optional(number, 1)
      extra_scrape_configs = optional(any, [])
      extra_configs        = optional(any, {})
    }), {})
    extra_configs = optional(any, {})
  })
  description = "Values for the VictoriaMetrics cluster, Operator, and selected VMAgent collector."
  default     = {}

  validation {
    condition = (
      length(var.victoria_metrics.agent.name) <= 253 &&
      alltrue([
        for label in split(".", var.victoria_metrics.agent.name) :
        length(label) >= 1 &&
        length(label) <= 63 &&
        can(regex("^[a-z0-9]([-a-z0-9]*[a-z0-9])?$", label))
      ])
    )
    error_message = "victoria_metrics.agent.name must be a valid Kubernetes DNS subdomain name."
  }

  validation {
    condition = (
      var.victoria_metrics.agent.replica_count >= 1 &&
      floor(var.victoria_metrics.agent.replica_count) ==
      var.victoria_metrics.agent.replica_count
    )
    error_message = "victoria_metrics.agent.replica_count must be a positive integer."
  }
}
```

- [ ] **Step 2: Prove transparent forwarding and no wrapper resources**

Keep these direct assignments:

```hcl
metrics_collector = var.metrics_collector
victoria_metrics  = var.victoria_metrics
```

Verify them and the absence of wrapper-owned monitoring objects:

```sh
rg -n '^\s*metrics_collector\s*=\s*var\.metrics_collector\s*$' main.tf
rg -n '^\s*victoria_metrics\s*=\s*var\.victoria_metrics\s*$' main.tf
! rg -q 'resource\s+"[^\"]+"\s+"[^\"]*(operator|vmagent|vm_service_scrape)' . --glob '*.tf'
```

- [ ] **Step 3: Run the GREEN sentinel probe**

```sh
printf '%s\n' '[var.victoria_metrics.operator.chart_version, var.victoria_metrics.operator.release_name, var.victoria_metrics.agent.name, tostring(var.victoria_metrics.agent.replica_count)]' | terraform console -var-file=tests/metrics-collector-selection/contract.tfvars
```

Expected output contains, in order,
`"0.67.2-wrapper-contract"`,
`"victoria-metrics-operator-contract"`,
`"victoria-metrics-agent-contract"`, and `"2"`. This plus the direct forwarding
assertion proves the wrapper does not drop or transform the nested contract.

- [ ] **Step 4: Update all active wrapper documentation**

Synchronize the listed README/design/spec/plan/data-model/quickstart/contract/
tasks files with both-enabled modes, Prometheus CRD ownership, Operator chart
version, monitor conversion, the chart's wildcard Secret RBAC boundary, the KSM
native-object exception, queue gates, and rollback. Remove old
`agent.chart_version`/`agent.release_name` examples except where explicitly
described as removed history.

- [ ] **Step 5: Initialize, format, and validate the wrapper and examples**

```sh
terraform fmt -check variables.tf main.tf tests/base/1-example.tf tests/base-with-victoria-metrics/1-example.tf
terraform init -backend=false -lockfile=readonly
terraform validate
cd tests/base
terraform init -backend=false -lockfile=readonly
terraform validate
cd ../base-with-victoria-metrics
terraform init -backend=false -lockfile=readonly
terraform validate
```

Expected: every command exits 0 while `module "this"` still uses the user's
current local absolute base-module source for workspace validation.

- [ ] **Step 6: Record the wrapper release gate without inventing a version**

Do not replace the current local source or uncomment a guessed registry version.
Publishing the wrapper is blocked until a base-module release containing this
contract exists and its exact version is provided. At release time only, restore
`source = "dasmeta/grafana/onpremise"`, pin that real published version, rerun
initialization/validation, and document the dependency.

### Task 12: Final cross-repository verification

**Files:**

- Verify all files listed in the file responsibility map.

- [ ] **Step 1: Run base initialization, validation, and focused tests**

```sh
cd /Users/vazgen/work/Dasmeta/modules/terraform-onpremise-grafana
terraform init -backend=false -lockfile=readonly
terraform validate
cd tests/metrics-collector-selection
terraform init -backend=false -lockfile=readonly
terraform test
```

Expected: all commands exit 0 and Terraform reports `0 failed`, including valid
modes, invalid CRD ownership, all invalid DNS/replica cases, protected values,
exact native KSM object counts, custom-job suppression, and VM storage
stability.

- [ ] **Step 2: Run focused base formatting**

```sh
cd /Users/vazgen/work/Dasmeta/modules/terraform-onpremise-grafana
terraform fmt -check variables.tf locals.tf main.tf outputs.tf modules/prometheus modules/victoria-metrics modules/kube-state-metrics tests/metrics-collector-selection
```

Expected: exit 0 without rewriting unrelated dashboard-alert changes.

- [ ] **Step 3: Re-run all wrapper checks from Task 11**

First return to the wrapper root:

```sh
cd /Users/vazgen/work/Dasmeta/modules/terraform-aws-grafanav12
```

Expected: the sentinel console probe, direct forwarding assertions, wrapper root
validation, Prometheus-first example, and Victoria example all pass against the
local base module.

- [ ] **Step 4: Check only active source/docs for removed resources and fields**

```sh
set +e
rg -n 'resource\s+"helm_release"\s+"vmagent"|agent_(chart_version|release_name)|agent\.(chart_version|release_name)' \
  /Users/vazgen/work/Dasmeta/modules/terraform-onpremise-grafana/variables.tf \
  /Users/vazgen/work/Dasmeta/modules/terraform-onpremise-grafana/main.tf \
  /Users/vazgen/work/Dasmeta/modules/terraform-onpremise-grafana/locals.tf \
  /Users/vazgen/work/Dasmeta/modules/terraform-onpremise-grafana/outputs.tf \
  /Users/vazgen/work/Dasmeta/modules/terraform-onpremise-grafana/versions.tf \
  /Users/vazgen/work/Dasmeta/modules/terraform-onpremise-grafana/modules \
  /Users/vazgen/work/Dasmeta/modules/terraform-onpremise-grafana/tests \
  /Users/vazgen/work/Dasmeta/modules/terraform-aws-grafanav12/data.tf \
  /Users/vazgen/work/Dasmeta/modules/terraform-aws-grafanav12/locals.tf \
  /Users/vazgen/work/Dasmeta/modules/terraform-aws-grafanav12/main.tf \
  /Users/vazgen/work/Dasmeta/modules/terraform-aws-grafanav12/moved.tf \
  /Users/vazgen/work/Dasmeta/modules/terraform-aws-grafanav12/output.tf \
  /Users/vazgen/work/Dasmeta/modules/terraform-aws-grafanav12/variables.tf \
  /Users/vazgen/work/Dasmeta/modules/terraform-aws-grafanav12/versions.tf \
  /Users/vazgen/work/Dasmeta/modules/terraform-aws-grafanav12/tests \
  --glob '*.tf' --glob '*.tftest.hcl'
VMOP_ACTIVE_FIELD_STATUS=$?
rg -U -P -q '(?s)agent\s*=\s*optional\(object\(\{.{0,1200}?\b(?:chart_version|release_name)\s*=' \
  /Users/vazgen/work/Dasmeta/modules/terraform-onpremise-grafana/variables.tf \
  /Users/vazgen/work/Dasmeta/modules/terraform-aws-grafanav12/variables.tf
VMOP_NESTED_SCHEMA_STATUS=$?
rg -U -P -q '(?s)agent\s*=\s*\{.{0,600}?\b(?:chart_version|release_name)\s*=' \
  /Users/vazgen/work/Dasmeta/modules/terraform-onpremise-grafana/README.md \
  /Users/vazgen/work/Dasmeta/modules/terraform-onpremise-grafana/tests \
  /Users/vazgen/work/Dasmeta/modules/terraform-aws-grafanav12/README.md \
  /Users/vazgen/work/Dasmeta/modules/terraform-aws-grafanav12/tests
VMOP_NESTED_EXAMPLE_STATUS=$?
set -e

for VMOP_SEARCH_STATUS in \
  "$VMOP_ACTIVE_FIELD_STATUS" \
  "$VMOP_NESTED_SCHEMA_STATUS" \
  "$VMOP_NESTED_EXAMPLE_STATUS"
do
  case "$VMOP_SEARCH_STATUS" in
    0) exit 1 ;;
    1) ;;
    *) exit "$VMOP_SEARCH_STATUS" ;;
  esac
done
```

Expected: no active source or current consumer HCL example references the
removed standalone contract. The first search catches dotted/child identifiers
in Terraform, and the two multiline predicates catch nested object
declarations/examples, including fenced README examples without rejecting
ordinary migration prose. Historical design/spec packages are reviewed for
explicit past-tense wording separately, not included in this zero-match gate.

- [ ] **Step 5: Run read-only diff and index hygiene**

In each repository run:

```sh
git diff --check
git diff --cached --check
git status --short
```

Expected: no whitespace errors and no newly staged files. Existing unrelated
dirty files remain untouched. Do not mutate git state.

- [ ] **Step 6: Prepare the live rollout handoff**

Use `specs/004-metrics-collector-selection/quickstart.md`. Do not claim live
success until Operator readiness, source/converted authorization selectors,
healthy application targets, required metrics, queue health, exactly one
converged scraper, and unchanged PVC identities are observed. Never print the
source or generated Secret value.
