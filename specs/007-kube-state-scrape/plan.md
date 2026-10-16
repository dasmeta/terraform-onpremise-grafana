# kube-state-metrics Annotation-Scrape Fix Plan

## Pre-change evidence

- The live stack has two scrape paths for standalone kube-state-metrics. Its
  `ServiceMonitor` target is healthy at `/metrics`; the legacy
  `kubernetes-service-monitor` job discovers the same Service through
  `prometheus.io/scrape: "true"`, replaces the path with an empty annotation,
  requests `/`, and receives HTML.
- The child module currently owns the Service port and ServiceMonitor but does
  not own `service.annotations`, allowing the chart default to opt into the
  legacy job.
- The existing `kube_state_metrics_values_are_collector_owned` native test is
  the right regression surface. It already verifies module-owned Helm values
  override conflicting `extra_configs` and that the ServiceMonitor remains
  enabled.

## Scope and design

Add `service.annotations = { "prometheus.io/scrape" = "false" }` to the
module-owned Helm values in `modules/kube-state-metrics/locals.tf`. Because the
module passes `extra_configs` before selector-owned values, the safe opt-out
wins over consumer-provided annotations. The existing ServiceMonitor remains
enabled and keeps its release label and `/metrics` path.

No public input is added, no resource address changes, and no provider version
change is required. This is an improve-mode bug fix; the Modern Capabilities
Rule is not active. The repository remains an opinionated wrapper around the
kube-state-metrics Helm chart rather than exposing a new chart pass-through.

## Files

| File | Change |
| --- | --- |
| `modules/kube-state-metrics/locals.tf` | Make the Service opt out of legacy annotation discovery. |
| `tests/metrics-collector-selection/3-operator-values.tftest.hcl` | Extend the existing collector-owned values assertion to cover the opt-out and preservation against conflicting user values. |
| `README.md` | Regenerate module documentation after the behavior note is updated, if the repository documentation generator changes it. |

## Validation

1. Add the native assertion first; it must fail against the unmodified module.
2. Add the minimal module-owned annotation value.
3. Run `terraform fmt` for changed HCL.
4. Initialize the focused test module without a backend and run its native test
   file.
5. Run `terraform validate` for the root module after initialization.

## Compatibility and release

- Existing ServiceMonitor behavior is preserved.
- The legacy annotation path no longer targets kube-state-metrics; this removes
  duplicate ingestion and the broken target.
- After a module release, the AWS wrapper must be bumped to the new on-premise
  version, then the Sela YAML must select the corresponding AWS release.
