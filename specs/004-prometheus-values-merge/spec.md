# Feature Specification: Preserve Prometheus extra values with VictoriaMetrics remote write

**Feature Branch**: `004-prometheus-values-merge`
**Created**: 2026-10-08
**Status**: Draft
**Input**: Backport a backward-compatible deep merge for Prometheus extra values and generated VictoriaMetrics remote write, without changing exporter ownership.

## User Scenarios & Testing

### User Story 1 - Combine Prometheus scheduling with remote write (Priority: P1)

An infrastructure consumer enables VictoriaMetrics and supplies Kubernetes scheduling fields in `prometheus.extra_configs.prometheus.prometheusSpec`. The module retains both the consumer-supplied fields and the generated VictoriaMetrics `remoteWrite` destination in the rendered Prometheus chart values.

**Why this priority**: The current shallow merge removes the consumer's entire `prometheus` values map whenever VictoriaMetrics is enabled, silently discarding scheduling and other supported Prometheus-spec settings.

**Independent Test**: A Terraform example enables VictoriaMetrics and supplies `nodeSelector` and `tolerations` below `prometheusSpec`; an assertion proves those fields and the generated `remoteWrite` URL are both present in the computed chart values.

**Acceptance Scenarios**:

1. **Given** VictoriaMetrics is enabled and a caller supplies `prometheusSpec.nodeSelector`, **When** the module calculates Prometheus Helm values, **Then** the selector and generated VictoriaMetrics remote-write target remain present.
2. **Given** VictoriaMetrics is enabled and a caller supplies `prometheusSpec.tolerations`, **When** the module calculates Prometheus Helm values, **Then** the tolerations and generated VictoriaMetrics remote-write target remain present.
3. **Given** VictoriaMetrics is disabled, **When** the module calculates Prometheus Helm values, **Then** caller-provided `prometheus.extra_configs` behavior remains unchanged.

---

### User Story 2 - Preserve current component ownership (Priority: P2)

An existing consumer upgrades to the backport release without adopting the newer collector architecture. The kube-prometheus-stack continues to own kube-state-metrics and node-exporter exactly as it did in the 1.28.0 baseline.

**Why this priority**: The broader released fix changes exporter ownership and can invalidate existing chart-extra configuration, which is outside this bounded correction.

**Independent Test**: The existing base example still renders the kube-prometheus-stack values without disabling its embedded kube-state-metrics or node-exporter components and no standalone replacement releases are introduced.

**Acceptance Scenarios**:

1. **Given** an existing caller configuration, **When** the backport is applied, **Then** the module creates the same component set as the 1.28.0 baseline.
2. **Given** a caller configures kube-state-metrics or node-exporter through existing Prometheus chart extra values, **When** the backport is applied, **Then** those values continue to be passed to kube-prometheus-stack.

## Edge Cases

- A caller supplies other `prometheusSpec` settings in addition to scheduling fields; the generated remote-write list must augment rather than replace the object.
- A caller supplies a `remoteWrite` value; the module-defined VictoriaMetrics destination remains authoritative for the VictoriaMetrics-enabled integration and must not be removed by the merge.
- A caller supplies extra values outside the top-level `prometheus` key; those values must retain the existing shallow-map behavior.

## Requirements

### Functional Requirements

- **FR-001**: When VictoriaMetrics is enabled, the module MUST combine caller-provided `prometheus.extra_configs.prometheus.prometheusSpec` fields with the generated `remoteWrite` configuration.
- **FR-002**: The combined value MUST preserve caller `nodeSelector` and `tolerations` fields exactly.
- **FR-003**: The module MUST retain the existing generated VictoriaMetrics remote-write endpoint when VictoriaMetrics is enabled.
- **FR-004**: The change MUST preserve the 1.28.0 component ownership model; it MUST NOT introduce standalone kube-state-metrics, node-exporter, VictoriaMetrics Operator, or VMAgent releases.
- **FR-005**: The module MUST retain existing behavior for callers that do not enable VictoriaMetrics.
- **FR-006**: The module MUST add a regression test that proves the merged computed values include both caller scheduling fields and generated remote write.
- **FR-007**: The module MUST document the merge behavior and supported caller override boundary.

## Success Criteria

### Measurable Outcomes

- **SC-001**: The regression test fails on the 1.28.0 baseline and passes after the backport.
- **SC-002**: Terraform validation succeeds for the changed module and its relevant test example.
- **SC-003**: The computed Prometheus values retain both a caller `nodeSelector`/`tolerations` pair and the generated remote-write URL in the VictoriaMetrics-enabled test.
- **SC-004**: The changed module source does not add or remove Helm releases relative to the 1.28.0 baseline.

## Assumptions

- This feature is a backward-compatible maintenance correction to the existing `prometheus.extra_configs` interface, not a new broad pass-through interface.
- The generated VictoriaMetrics remote-write destination remains the module-owned integration setting.
- The target release strategy will be determined during planning because the existing 1.28.x tags after 1.28.0 contain unrelated architecture changes.
