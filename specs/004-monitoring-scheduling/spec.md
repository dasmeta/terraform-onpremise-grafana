# Feature Specification: Preserve monitoring workload scheduling

**Feature Branch**: `004-monitoring-scheduling`  
**Created**: 2026-10-09  
**Status**: Draft  
**Input**: Preserve caller-provided Kubernetes scheduling values through the Grafana monitoring module's Helm releases.

## User Scenarios & Testing

### User Story 1 - Schedule stateful monitoring workloads (Priority: P1)

A platform operator supplies a node selector and matching NoSchedule toleration through the established `extra_configs` interface and expects every supported stateful monitoring workload to receive those values.

**Why this priority**: These workloads require isolation from volatile capacity without introducing a new module interface.

**Independent Test**: A Terraform test inspects each target Helm release's final values and finds the caller's selector and toleration.

**Acceptance Scenarios**:

1. **Given** caller scheduling values for Prometheus and Alertmanager, **When** the module renders Helm values, **Then** both workload specifications retain them alongside module-managed remote-write configuration.
2. **Given** caller scheduling values for VictoriaMetrics, Tempo, and Loki, **When** the module renders Helm values, **Then** the relevant chart workload maps retain them alongside module-managed integration values.

### User Story 2 - Preserve existing integration guarantees (Priority: P2)

An operator continues to use the module's selected metrics backend and monitoring integrations while supplying workload scheduling values.

**Why this priority**: Scheduling must not weaken endpoint, remote-write, or collector-selection guarantees.

**Independent Test**: Existing selector-owned assertions pass together with the new scheduling assertions.

**Acceptance Scenarios**:

1. **Given** scheduling values and a configured metrics collector, **When** the module renders Helm values, **Then** module-owned integration fields retain their configured values.

### Edge Cases

- A caller omits scheduling values: generated Helm values retain current behavior.
- A caller supplies only a node selector or only tolerations: the supplied field is preserved without requiring the other.
- Node-wide DaemonSets remain unaffected by this feature.

## Requirements

### Functional Requirements

- **FR-001**: The module MUST preserve caller-defined Prometheus and Alertmanager scheduling values in final Helm values.
- **FR-002**: The module MUST preserve caller-defined VictoriaMetrics component scheduling values in final Helm values.
- **FR-003**: The module MUST preserve caller-defined Tempo and Loki single-binary scheduling values in final Helm values.
- **FR-004**: The module MUST retain module-owned collector, remote-write, endpoint, and monitoring fields.
- **FR-005**: The module MUST not add a new public input or alter existing caller input shapes.
- **FR-006**: The module MUST include automated regression coverage for the final Helm values.

## Success Criteria

### Measurable Outcomes

- **SC-001**: Focused Terraform tests assert selector and toleration retention for all five target chart releases.
- **SC-002**: Existing metrics-collector selection tests continue to pass.
- **SC-003**: Terraform validation succeeds without modifying the public input schema.

## Assumptions

- Existing `extra_configs` maps are the supported caller interface.
- The module remains an opinionated Helm wrapper; the change is a compatibility fix, not a generic scheduling abstraction.
- The target release is a backward-compatible patch release.
