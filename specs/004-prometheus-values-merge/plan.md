# Implementation Plan: Preserve Prometheus Extra Values with VictoriaMetrics Remote Write

**Branch**: `004-prometheus-values-merge` | **Date**: 2026-10-08 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `specs/004-prometheus-values-merge/spec.md`

## Summary

Correct the VictoriaMetrics-enabled Prometheus values path in the 1.28.0
module baseline. The implementation will construct a nested `prometheus` /
`prometheusSpec` map that combines caller-supplied chart values with the
module-owned VictoriaMetrics remote-write list, instead of allowing Terraform's
shallow `merge` to replace the caller map. No module input, Helm release, chart
version, or exporter ownership changes.

## Technical Context

**Language/Version**: Terraform HCL, module constraint `~> 1.3`
**Primary Dependencies**: `kube-prometheus-stack` Helm chart 75.8.0, existing VictoriaMetrics cluster module, existing local Helm-values renderer
**Storage**: N/A
**Testing**: Terraform formatting, validation, and a focused local test fixture that asserts the computed Helm values
**Target Platform**: Kubernetes clusters using the Grafana on-premise module
**Project Type**: Terraform module
**Performance Goals**: No added runtime resources or requests
**Constraints**: Preserve the v1.28.0 release topology; preserve caller values outside the module-owned generated remote-write field; do not introduce a broader pass-through interface
**Scale/Scope**: `locals.tf`, `main.tf`, one focused test fixture, and README documentation

## Constitution Check

- **Speckit evidence**: active package is `specs/004-prometheus-values-merge/`; this plan and the following task list are required before Terraform files change.
- **Repository scope**: PASS. The correction is limited to `terraform-onpremise-grafana`; the consuming infrastructure repository remains unchanged until this module is released.
- **Wrapper preservation**: PASS. The existing grouped `prometheus` object and its optional `extra_configs` field remain the interface. No variable or output is added.
- **Backward compatibility**: PASS by design. The fix affects only the existing VictoriaMetrics-enabled merge; disabled VictoriaMetrics and unrelated top-level extra values retain their current behavior.
- **Modern Capabilities Rule**: not applicable. This is an improve-mode correction to established Helm values, not a new capability or provider surface.
- **Module-change gate**: expected to pass after `spec.md`, this `plan.md`, `tasks.md`, tests, and README are committed together.
- **Release constraint**: published later 1.28.x versions include unrelated collector/exporter topology changes. A maintainer must assign a distinct compatible release/version for this isolated backport; tagging/releasing is not part of the source edit.

## Research Decisions

1. Use explicit nested Terraform `merge` expressions rather than a provider or new dependency. Terraform map merge is shallow; composing `prometheus` and then `prometheusSpec` explicitly preserves `nodeSelector`, `tolerations`, and other supported caller fields.
2. Keep the module-generated `remoteWrite` list authoritative while VictoriaMetrics is enabled. This retains the existing integration endpoint and prevents a caller from unintentionally removing it.
3. Retain the existing top-level merge behavior for unrelated chart values. The correction must not recursively merge arbitrary caller data or broaden the module contract.
4. Do not adopt onpremise 1.28.5+ in this change. Those releases split kube-state-metrics and node-exporter into separate releases and are a separate migration.

## Project Structure

### Documentation

```text
specs/004-prometheus-values-merge/
├── spec.md
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
└── tasks.md
```

### Source and Test Files

```text
locals.tf                                      # Compose effective Prometheus extra values
main.tf                                        # Pass the composed values to modules/prometheus
README.md                                      # Document the VictoriaMetrics merge boundary
tests/prometheus-victoria-metrics-merge/
├── 1-example.tf                               # VictoriaMetrics-enabled caller fixture
└── README.md                                  # Focused validation instructions
tests/prometheus-without-victoria-metrics-merge/
├── 1-example.tf                               # VictoriaMetrics-disabled caller fixture
└── README.md                                  # Compatibility assertion instructions
```

**Structure Decision**: The behavior remains at the root module boundary where
the VictoriaMetrics URL is known. `modules/prometheus` remains a generic Helm
renderer and receives a single already-composed `extra_configs` map.

## Implementation Steps

1. Add a failing focused fixture that enables VictoriaMetrics and supplies
   `prometheus.prometheusSpec.nodeSelector` and `tolerations`; assert that the
   computed values contain those fields plus the generated remote-write URL.
2. Refactor `locals.tf` to calculate an effective Prometheus extra-values map:
   retain `var.prometheus.extra_configs`, overlay a nested `prometheus` map,
   overlay a nested `prometheusSpec` map, and set the existing generated
   `remoteWrite` list only when VictoriaMetrics is enabled.
3. Change `main.tf` to pass the effective local map to `modules/prometheus`.
4. Add a disabled-VictoriaMetrics fixture proving caller scheduling values
   remain unchanged and `remoteWrite` is absent when no generated map is
   required.
5. Document that caller fields under `prometheus.prometheusSpec` are preserved
   while module-managed `remoteWrite` remains authoritative when VictoriaMetrics
   is enabled.
6. Run `terraform fmt -check`, `terraform validate`, the focused regression
   fixture, and a topology guard that verifies no standalone exporter module or
   Helm release was added.

## Validation and Rollback

- The pre-change fixture must fail because `nodeSelector` and `tolerations` are
  absent from the effective values when VictoriaMetrics is enabled.
- The post-change fixture must prove both scheduling fields and the generated
  remote-write URL exist.
- Compare the Terraform plan/resource graph with the v1.28.0 baseline; no new
  Helm releases or ownership changes are acceptable.
- Roll back by reverting the single local-map and module-input changes. This
  restores the previous shallow merge behavior without state migration.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| None | N/A | N/A |
