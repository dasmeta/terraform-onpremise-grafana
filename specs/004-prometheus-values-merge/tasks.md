# Tasks: Preserve Prometheus Extra Values with VictoriaMetrics Remote Write

**Input**: `spec.md`, `plan.md`, `research.md`, `data-model.md`, and `quickstart.md` in this feature package
**Prerequisites**: Review and approval of `plan.md`
**Tests**: Required. This is a regression fix; the focused fixture must fail on the v1.28.0 baseline and pass after the implementation.

## Phase 1: Regression Fixture

**Purpose**: Prove the existing shallow merge drops caller scheduling values while retaining generated remote write.

- [x] T001 Create `tests/prometheus-victoria-metrics-merge/1-example.tf` with a local module call to `../..` that enables Prometheus and VictoriaMetrics and passes these fields in `prometheus.extra_configs`:

  ```hcl
  prometheus = {
    extra_configs = {
      prometheus = {
        prometheusSpec = {
          nodeSelector = { workload = "monitoring" }
          tolerations = [{
            key      = "workload"
            operator = "Equal"
            value    = "monitoring"
            effect   = "NoSchedule"
          }]
        }
      }
    }
  }

  victoria_metrics = { enabled = true }
  ```

  Disable unrelated Grafana dashboard and alert paths only as required by the existing test conventions; do not add standalone exporter configuration.

- [x] T002 Add `tests/prometheus-victoria-metrics-merge/README.md` with the exact regression command sequence:

  ```bash
  terraform -chdir=tests/prometheus-victoria-metrics-merge init -input=false
  terraform -chdir=tests/prometheus-victoria-metrics-merge plan -out=tfplan -input=false
  terraform -chdir=tests/prometheus-victoria-metrics-merge show -json tfplan \
    | jq -e '
        [ .resource_changes[]
          | select(.type == "helm_release" and .name == "prometheus")
          | .change.after.values[]?
          | (fromjson? // {})
          | .prometheus.prometheusSpec? // empty
        ] as $specs
        | any($specs[];
            .nodeSelector.workload == "monitoring"
            and (.tolerations | any(.[];
              .key == "workload"
              and .operator == "Equal"
              and .value == "monitoring"
              and .effect == "NoSchedule"
            ))
            and (.remoteWrite | any(.[];
              .url == "http://victoria-metrics-victoria-metrics-cluster-vminsert.monitoring.svc.cluster.local:8480/insert/0/prometheus/api/v1/write"
            ))
          )'
  ```

  This assertion locates the planned Prometheus Helm-release `values`, decodes
  the JSON values document, and requires all three fields.

- [x] T003 Run the fixture against the unmodified baseline and record the expected non-zero assertion result: the generated remote-write URL exists but caller `nodeSelector` and `tolerations` do not. Do not change module source before observing this failure.

## Phase 2: Backward-Compatible Merge

**Purpose**: Preserve caller Prometheus-spec values alongside generated remote write without changing module topology.

- [x] T004 Modify `locals.tf` to define `prometheus_effective_extra_configs`. It must:

  1. retain `var.prometheus.extra_configs` when VictoriaMetrics is disabled;
  2. retain caller top-level extra values when VictoriaMetrics is enabled;
  3. retain caller `prometheus` values;
  4. retain caller `prometheusSpec` fields; and
  5. set the existing generated `remoteWrite` list under `prometheus.prometheusSpec` when VictoriaMetrics is enabled.

  Use explicit nested Terraform `merge` expressions and `try(..., {})` for optional map levels. Do not add a variable, provider, Helm release, or child module.

- [x] T005 Modify `main.tf` so `module "prometheus"` receives `local.prometheus_effective_extra_configs` instead of the current shallow merge expression.

- [x] T006 Run `terraform fmt -check` and the T002 command. Expected: formatting succeeds; the full `jq` assertion succeeds; the generated remote-write URL remains present; caller node selector and toleration remain present.

## Phase 3: Compatibility Coverage and Documentation

**Purpose**: Demonstrate that the correction does not change disabled-VictoriaMetrics behavior or exporter ownership.

- [x] T007 Extend the focused fixture or add a second fixture input that leaves VictoriaMetrics disabled and supplies a caller `prometheusSpec.nodeSelector`. Assert the caller value is still present and no generated VictoriaMetrics remote-write URL is present.

- [x] T008 Add a topology guard to the fixture README command sequence that checks the planned addresses for no standalone kube-state-metrics, node-exporter, VictoriaMetrics Operator, or VMAgent Helm release. The guard must compare the plan with the v1.28.0 component set.

- [x] T009 Update `README.md` beside the Prometheus/VictoriaMetrics configuration guidance: caller fields under `prometheus.extra_configs.prometheus.prometheusSpec` are preserved, while the VictoriaMetrics-enabled remote-write destination remains module-managed.

- [x] T010 Run `terraform validate` from the module root and the focused fixture, run `git diff --check`, and inspect the diff. Confirm the changed files are limited to `locals.tf`, `main.tf`, the focused test fixture, its README, feature-package evidence, and the module README.

## Phase 4: Review and Release Handoff

**Purpose**: Ensure the backport can be reviewed and released without implying the later collector migration.

- [x] T011 Commit the module implementation, fixture, README, and Speckit package with a message that identifies the Prometheus values merge correction.

- [ ] T012 Request review with the failing-baseline evidence, passing fixture evidence, topology guard output, and a release note: a maintainer must select a distinct compatible release/version for the isolated v1.28.0-based backport. Do not tag or publish a module release without maintainer authority.

## Dependencies and Execution Order

- T001–T003 establish the red regression proof and must complete before T004.
- T004–T005 implement the smallest source change.
- T006 proves the green regression result.
- T007–T010 establish compatibility and documentation.
- T011–T012 happen only after all validations pass.
