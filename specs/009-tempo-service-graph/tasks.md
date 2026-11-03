# Tempo Service Map Integration Tasks

**Feature**: `009-tempo-service-graph`
**Spec**: [spec.md](spec.md)
**Plan**: [plan.md](plan.md)

## Task 1: Add the failing native regression test

**Files:**

- Create: `tests/tempo-service-graph.tftest.hcl`
- Create: `tests/tempo-service-graph-tempo.tftest.hcl`

- [ ] **Step 1: Add four mocked-provider plan runs directly under `tests/`**

  Declare mocked `helm`, `grafana`, `random`, and `time` providers. The root
  module's aggregate Grafana output includes provider-produced metadata, so
  execute its two runs with `command = apply` to make the datasource-output
  assertions known. This file's runs exercise the repository root directly,
  so omit the `module` block:

  ```hcl
  run "tempo_with_victoria_metrics_uses_the_existing_datasource" {
    command = apply
    module { source = ".." }
    variables {
      grafana_admin_password = "test-password"
      metrics_collector      = "victoria_metrics"
      grafana                = { enabled = true }
      tempo                  = { enabled = true }
      victoria_metrics       = { enabled = true, operator = { enabled = true } }
    }
    assert {
      condition = try(alltrue([
        jsondecode(output.grafana.datasources.Tempo.encoded_json).tracesToMetrics.datasourceUid == "victoriametrics",
        jsondecode(output.grafana.datasources.Tempo.encoded_json).serviceMap.datasourceUid == "victoriametrics",
        jsondecode(output.grafana.datasources.Tempo.encoded_json).nodeGraph.enabled,
      ]), false)
      error_message = "The built-in Tempo datasource must use VictoriaMetrics for trace metrics and topology views."
    }
  }
  ```

  Add the same root module configuration with `victoria_metrics = { enabled = false }`
  and `metrics_collector = "prometheus"`; assert `tracesToMetrics.datasourceUid ==
  "prometheus"` and that `serviceMap` and `nodeGraph` keys are absent.

  Put the two direct Tempo-child runs in
  `tests/tempo-service-graph-tempo.tftest.hcl`, with only a mocked `helm`
  provider and `module { source = "./modules/tempo" }`. Both use
  `service_graph_enabled = true`: one omits
  dimensions and asserts processor names plus absence of `processor`, while
  the other passes `service_graph_dimensions = ["deployment.environment.name"]`
  and asserts that both `service_graphs` and `span_metrics` receive that list
  and `enable_client_server_prefix = true`.

- [ ] **Step 2: Initialize the untouched module and run the new test (red)**

  Run:

  ```bash
  terraform init -backend=false
  terraform test -filter=tests/tempo-service-graph.tftest.hcl
  ```

  Expected: the new datasource and child-module input assertions fail because
  `victoriametrics` service-map JSON and the child variables do not exist yet.
  A provider-installation failure is not an acceptable red result; initialize
  first and resolve only test syntax/configuration errors before proceeding.

## Task 2: Wire the automatic root-module integration

**Files:**

- Modify: `variables.tf` in `variable "tempo"`
- Modify: `main.tf` in `module "grafana"` and `module "tempo"`
- Modify: `modules/grafana/variables.tf`
- Modify: `modules/grafana/locals.tf`

- [ ] **Step 1: Add the public optional dimensions attribute**

  Add this grouped-object field beside `metrics_generator` in root
  `variable "tempo"`:

  ```hcl
  service_graph_dimensions = optional(list(string), []) # Optional Tempo metric labels from trace attributes; each label increases series cardinality.
  ```

  Keep every grouped-object field documented inline and leave the default empty
  so existing callers generate no extra labels.

- [ ] **Step 2: Pass derived private wiring to the two child modules**

  In `module "grafana"`, pass:

  ```hcl
  tempo_service_graph_datasource_uid = var.victoria_metrics.enabled ? "victoriametrics" : null
  ```

  In `module "tempo"`, pass:

  ```hcl
  service_graph_enabled    = var.victoria_metrics.enabled
  service_graph_dimensions = var.tempo.service_graph_dimensions
  ```

  The child receives an explicit root-derived state rather than rediscovering
  a sibling module. This keeps automatic activation limited to Tempo plus
  VictoriaMetrics and preserves the public grouped root interface.

- [ ] **Step 3: Add the internal Grafana input and extend only the built-in Tempo JSON**

  Add this nullable child variable in `modules/grafana/variables.tf`:

  ```hcl
  variable "tempo_service_graph_datasource_uid" {
    type        = string
    default     = null
    nullable    = true
    description = "Internal UID for Tempo service-map and node-graph queries; null keeps the existing Tempo datasource JSON."
  }
  ```

  Replace the Tempo `encoded_json` object in `modules/grafana/locals.tf` with
  the following merge, retaining the existing `tracesToLogsV2` link and UID:

  ```hcl
  encoded_json = jsonencode(merge({
    httpMethod = "GET"
    tracesToLogsV2 = { datasourceUid = "loki" }
    tracesToMetrics = {
      datasourceUid = coalesce(var.tempo_service_graph_datasource_uid, var.default_metrics_datasource_uid)
    }
    }, var.tempo_service_graph_datasource_uid == null ? {} : {
    serviceMap = { datasourceUid = var.tempo_service_graph_datasource_uid }
    nodeGraph  = { enabled = true }
  }))
  ```

- [ ] **Step 4: Re-run the datasource runs**

  Run:

  ```bash
  terraform fmt variables.tf main.tf modules/grafana/variables.tf modules/grafana/locals.tf
  terraform test -filter=tests/tempo-service-graph.tftest.hcl
  ```

  Expected: both root datasource runs pass; the processor runs still fail until
  Task 3 provides the Tempo-child variables and values.

## Task 3: Render Tempo processors and opt-in dimensions

**Files:**

- Modify: `modules/tempo/variables.tf`
- Modify: `modules/tempo/locals.tf`

- [ ] **Step 1: Add private Tempo-child inputs**

  Add the following variables with descriptions:

  ```hcl
  variable "service_graph_enabled" {
    type        = bool
    default     = false
    description = "Whether the parent has enabled the VictoriaMetrics-backed Tempo service graph."
  }

  variable "service_graph_dimensions" {
    type        = list(string)
    default     = []
    description = "Optional trace attribute labels added to Tempo service-graph and span-metrics series."
  }
  ```

- [ ] **Step 2: Render module-owned override values only when enabled**

  In `modules/tempo/locals.tf`, merge this object into the existing
  `tempo` member of `local.selector_owned_values` only when
  `var.service_graph_enabled` is true:

  ```hcl
  overrides = {
    defaults = {
      metrics_generator = merge({
        processors = ["local-blocks", "service-graphs", "span-metrics"]
        }, length(var.service_graph_dimensions) == 0 ? {} : {
        processor = {
          service_graphs = {
            dimensions                  = var.service_graph_dimensions
            enable_client_server_prefix = true
          }
          span_metrics = {
            dimensions                  = var.service_graph_dimensions
            enable_client_server_prefix = true
          }
        }
      })
    }
  }
  ```

  Preserve `metricsGenerator.remoteWriteUrl` and the existing
  `serviceMonitor` object. Caller `extra_configs` remains earlier in Helm
  values, so this supported interface is deterministically module-owned.

- [ ] **Step 3: Re-run the complete new test (green)**

  Run:

  ```bash
  terraform fmt modules/tempo/variables.tf modules/tempo/locals.tf
  terraform test -filter=tests/tempo-service-graph.tftest.hcl
  ```

  Expected: all four runs pass, proving both datasource modes and both
  dimension modes.

## Task 4: Document and regenerate interface documentation

**Files:**

- Modify: `README.md`

- [ ] **Step 1: Add a Tempo service-graph behavior section before the generated input table**

  Add a concise section stating that enabling both Tempo and VictoriaMetrics
  updates the single built-in Tempo datasource in place, uses the stable
  `victoriametrics` UID for traces-to-metrics and service maps, enables the
  node graph plus both metrics-generator processors, and does not create a
  second datasource. Document this opt-in example:

  ```hcl
  tempo = {
    enabled                  = true
    service_graph_dimensions = ["deployment.environment.name"]
  }

  victoria_metrics = {
    enabled = true
  }
  ```

  State that each additional dimension produces more metric series and
  remote-write traffic, so leave the list empty unless an operator needs to
  distinguish similarly named services.

- [ ] **Step 2: Regenerate README inputs and outputs using the repository hook**

  Run:

  ```bash
  pre-commit run terraform_docs --files README.md variables.tf outputs.tf
  ```

  Expected: generated `tempo` input table contains
  `service_graph_dimensions` and matches the current root variable definition.

## Task 5: Full verification, review, and delivery

**Files:**

- Verify: all files above

- [ ] **Step 1: Run full local verification**

  Run:

  ```bash
  terraform fmt -check -recursive
  terraform init -backend=false
  terraform validate
  terraform test
  pre-commit run --files variables.tf main.tf modules/grafana/variables.tf modules/grafana/locals.tf modules/tempo/variables.tf modules/tempo/locals.tf tests/tempo-service-graph.tftest.hcl README.md specs/009-tempo-service-graph/spec.md specs/009-tempo-service-graph/plan.md specs/009-tempo-service-graph/tasks.md
  git diff --check
  ```

  Record command output and do not claim the suite passes if Terraform’s
  native test command does not discover `tests/tempo-service-graph.tftest.hcl`.

- [ ] **Step 2: Perform a self-review against `origin/main`**

  Inspect:

  ```bash
  git diff --check origin/main...HEAD
  git diff --stat origin/main...HEAD
  git diff origin/main...HEAD -- variables.tf main.tf modules/grafana modules/tempo tests/tempo-service-graph.tftest.hcl README.md
  ```

  Confirm one existing Tempo datasource remains, no client-specific value
  appears, and VictoriaMetrics-disabled plans contain no dangling UID.

- [ ] **Step 3: Commit and create the upstream pull request only after review**

  Use conventional commits for the Speckit evidence and implementation. The PR
  description must state the automatic behavior, opt-in cardinality trade-off,
  test commands actually run, and the separate post-release AWS-wrapper PR
  dependency. Do not set the wrapper version until the upstream release exists.
