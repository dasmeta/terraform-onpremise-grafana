# Monitoring Scheduling Propagation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` (recommended) or `superpowers:executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Preserve caller scheduling values in the final Helm values for Prometheus, Alertmanager, VictoriaMetrics, Tempo, and Loki.

**Architecture:** Replace each affected `helm_release.values` list of independently encoded documents with one explicit, deep-merged map. Generated defaults are merged first, caller `extra_configs` second, and module-owned contract fields last. This protects integration guarantees while retaining caller-owned scheduling fields.

**Tech Stack:** Terraform HCL, `isometry/deepmerge`, HashiCorp Helm provider, native Terraform tests with mocked providers.

---

## Technical context and boundaries

- Target repository: `terraform-onpremise-grafana`, patching the `v1.28.5` baseline.
- Affected source: `modules/prometheus`, `modules/victoria-metrics`, `modules/tempo`, and `modules/loki-stack`.
- Existing public interface: component-specific `extra_configs` objects; it remains unchanged.
- Module-owned fields: collector enablement, remote-write endpoints, generated service endpoints, and monitoring enablement remain authoritative.
- Out of scope: Grafana/MySQL, Promtail, node-exporter, chart upgrades, and any manual cluster mutation.
- Modern-capabilities classification: **supported**. This is a Terraform expression-composition change; no new cloud/provider capability is introduced.
- Module-change gate: requires this feature's `spec.md`, `plan.md`, and `tasks.md` before implementation.

## File structure

```text
modules/prometheus/
  locals.tf                         # construct one final values map
  main.tf                           # encode only the final map
  versions.tf                       # declare deep-merge provider
modules/victoria-metrics/
  locals.tf                         # construct one final values map
  main.tf                           # encode only the final map
  versions.tf                       # declare deep-merge provider
modules/tempo/
  locals.tf                         # construct one final values map
  main.tf                           # encode only the final map
  versions.tf                       # declare deep-merge provider
modules/loki-stack/
  locals.tf                         # construct one final values map
  main.tf                           # encode only the final map
  versions.tf                       # declare deep-merge provider
tests/monitoring-scheduling/
  0-setup.tf                        # isolated test provider requirements
  1-scheduling-propagation.tftest.hcl # regression assertions at Helm boundary
README.md                           # document preserved scheduling values
```

## Task 1: Write the failing Helm-value regression tests

**Files:**
- Create: `tests/monitoring-scheduling/1-scheduling-propagation.tftest.hcl`

- [ ] Create mocked Terraform plan tests for the four child modules.

  Use a shared selector `{ workload = "monitoring" }` and a `NoSchedule` toleration. Configure:

  - Prometheus `extra_configs.prometheus.prometheusSpec` and `extra_configs.alertmanager.alertmanagerSpec`.
  - VictoriaMetrics `extra_configs.vminsert`, `vmselect`, and `vmstorage`.
  - Tempo `extra_configs.tempo`.
  - Loki `configs.loki.extra_configs.singleBinary`.

  Each assertion must require one final values document and decode its first entry:

  ```hcl
  condition = alltrue([
    length(helm_release.tempo.values) == 1,
    jsondecode(helm_release.tempo.values[0]).tempo.nodeSelector.workload == "monitoring",
    jsondecode(helm_release.tempo.values[0]).tempo.tolerations[0].effect == "NoSchedule",
    jsondecode(helm_release.tempo.values[0]).tempo.metricsGenerator.remoteWriteUrl == "http://vminsert.monitoring.svc.cluster.local:8480/insert/0/prometheus/api/v1/write",
  ])
  ```

- [ ] Run the focused test before implementation.

  Run: `terraform -chdir=tests/monitoring-scheduling test`

  Expected: FAIL. The baseline also rejects the heterogeneous Prometheus/Alertmanager Helm-values object while normalizing it, before it can compose the separate values documents.

## Task 2: Compose Prometheus and Alertmanager values once

**Files:**
- Modify: `modules/prometheus/locals.tf`
- Modify: `modules/prometheus/main.tf`
- Modify: `modules/prometheus/versions.tf`

- [ ] In `locals.tf`, decode the generated Prometheus template and build `effective_values` with `provider::deepmerge::mergo` in this order:

  ```hcl
  effective_values = provider::deepmerge::mergo(
    provider::deepmerge::mergo(
      yamldecode(templatefile("${path.module}/values/prometheus-values.yaml.tpl", local.template_vars)),
      local.effective_extra_configs,
    ),
    local.selector_owned_values,
  )
  ```

  Move existing template arguments into `local.template_vars`; `local.selector_owned_values` contains the existing CRD, kube-state-metrics, kubelet, node-exporter, and Prometheus enablement contract.

- [ ] Replace the multiple `helm_release.prometheus.values` entries with:

  ```hcl
  values = [jsonencode(local.effective_values)]
  ```

- [ ] Re-run the focused regression test and confirm Prometheus/Alertmanager assertions pass while the other module tests still fail.

## Task 3: Compose VictoriaMetrics, Tempo, and Loki values once

**Files:**
- Modify: `modules/victoria-metrics/locals.tf`
- Modify: `modules/victoria-metrics/main.tf`
- Modify: `modules/tempo/locals.tf`
- Modify: `modules/tempo/main.tf`
- Modify: `modules/loki-stack/locals.tf`
- Modify: `modules/loki-stack/main.tf`
- Modify: the four affected child-module `versions.tf` files

- [ ] Define `effective_values` in each module. Preserve the existing generated map and merge in this exact order:

  ```hcl
  effective_values = provider::deepmerge::mergo(
    provider::deepmerge::mergo(local.generated_values, var.extra_configs),
    local.selector_owned_values,
  )
  ```

  For Loki, use `var.configs.loki.extra_configs` and `local.selector_owned_monitoring_values`; for VictoriaMetrics, use `local.cluster_endpoint_contract`; for Tempo, use its existing metrics-generator and ServiceMonitor contract.

- [ ] Replace every target release's multiple JSON `values` entries with one `jsonencode(local.effective_values)` entry.

- [ ] Re-run the focused regression test. Expected: PASS for all four module tests, preserving caller scheduling and module-owned integration fields.

## Task 4: Document and validate the patch

**Files:**
- Modify: `README.md`
- Modify: `specs/004-monitoring-scheduling/tasks.md`

- [ ] Add a concise README note under custom Helm values: callers may safely set `nodeSelector` and `tolerations` in the established component `extra_configs` paths; module-owned integration fields remain authoritative.

- [ ] Create the task list, marking Task 1 as test-first and Tasks 2–3 as implementation after the red test.

- [ ] Run validation and regression suites.

  Run:

  ```bash
  terraform fmt -check -recursive
  terraform validate
  terraform -chdir=tests/monitoring-scheduling test
  terraform test -filter=tests/metrics-collector-selection
  ```

  Expected: formatting, validation, and focused scheduling coverage succeed. The legacy collector-selection filter must be checked for actual test discovery before treating its exit status as regression coverage.

## Release handoff

Publish a patch release of `dasmeta/grafana/onpremise`. Then create a separate patch release of the AWS wrapper that pins it, followed by a consumer IaC version bump and Terraform plan review. Rollback remains a version-pin reversal.
