# Feature Specification: VictoriaMetrics Datasource Resilience

**Feature Branch**: `fix-datasource-problem`  
**Created**: 2026-07-22  
**Status**: Draft  
**Input**: User description: "Persist the validated VictoriaMetrics datasource error mitigation from DS-11630 as the default module behavior so clients do not need per-environment YAML fixes."

## User Scenarios & Testing

### User Story 1 - Default Resilient VictoriaMetrics Queries (Priority: P1)

As an operator enabling the bundled VictoriaMetrics deployment, I want the default module configuration to tolerate one unavailable storage pod during normal query windows, so Grafana application alerts do not fan out datasource errors from a monitoring backend gap.

**Why this priority**: This directly addresses the observed datasource error incident and removes the need for client-specific YAML patches.

**Independent Test**: Plan the VictoriaMetrics module with default inputs and verify the generated Helm values include the validated resilient write/query arguments.

**Acceptance Scenarios**:

1. **Given** the VictoriaMetrics module is planned with default component settings, **When** the generated Helm values are inspected, **Then** `vminsert` uses replication factor 2.
2. **Given** the VictoriaMetrics module is planned with default component settings, **When** the generated Helm values are inspected, **Then** `vmselect` uses replication factor 2, deduplicates replicated samples, and skips slow replicas.
3. **Given** an operator supplies `extra_configs`, **When** the Helm release is rendered, **Then** the existing override path remains available after the module defaults.

---

### User Story 2 - Protected Grafana MySQL Primary (Priority: P2)

As an operator using the module-created Grafana MySQL database, I want the default MySQL primary pod to be protected from voluntary disruption, so Grafana does not lose its backing database during node consolidation.

**Why this priority**: This persists the earlier DS-11630 MySQL mitigation and removes the need for a per-client `mysql_extra_configs` patch.

**Independent Test**: Plan the Grafana module with default database creation enabled and verify the generated MySQL Helm values protect the primary pod with a do-not-disrupt annotation and a strict PDB.

**Acceptance Scenarios**:

1. **Given** the Grafana module is planned with its default created MySQL database, **When** the generated MySQL Helm values are inspected, **Then** the primary pod has `karpenter.sh/do-not-disrupt = "true"`.
2. **Given** the Grafana module is planned with its default created MySQL database, **When** the generated MySQL Helm values are inspected, **Then** the primary PDB has `minAvailable = 1`.
3. **Given** the primary PDB has `minAvailable = 1`, **When** the generated values are inspected, **Then** `maxUnavailable` remains empty so the chart does not allow voluntary disruption of the singleton primary.

### Edge Cases

- Existing consumers that override `extra_configs` must still be able to override chart settings when they intentionally choose a different replication or query behavior.
- Existing consumers that override `mysql_extra_configs` must still be able to override chart settings when they intentionally choose a different MySQL disruption policy.
- The default must not change replica counts or persistent volume defaults as part of this fix.
- The default should avoid client-specific names, namespaces, or hostnames.

## Requirements

### Functional Requirements

- **FR-001**: The module MUST default VictoriaMetrics write replication to two storage targets for new samples.
- **FR-002**: The module MUST default VictoriaMetrics query replication to match the write replication factor.
- **FR-003**: The module MUST default query deduplication for replicated samples.
- **FR-004**: The module MUST default query behavior to skip slow or unavailable replicas.
- **FR-005**: The module MUST preserve the existing consumer override mechanism for chart values.
- **FR-006**: The module MUST include an automated plan-time check proving the generated defaults are present.
- **FR-007**: The module-created Grafana MySQL primary pod MUST default to the `karpenter.sh/do-not-disrupt` annotation.
- **FR-008**: The module-created Grafana MySQL primary PDB MUST default to `minAvailable = 1` and no `maxUnavailable` value.
- **FR-009**: The module MUST preserve the existing `mysql_extra_configs` override mechanism for chart values.

## Success Criteria

### Measurable Outcomes

- **SC-001**: A module plan with default VictoriaMetrics settings includes all four validated resilience arguments.
- **SC-002**: A module plan with default Grafana-created MySQL settings includes the primary pod annotation and PDB policy.
- **SC-003**: The automated checks fail before defaults are added and pass after the module changes.
- **SC-004**: The change requires no client-specific YAML for the validated default paths.

## Assumptions

- The validated incident mitigation is the VictoriaMetrics replication approach recorded in DS-11630: RF=2 for writes and queries, deduplication, and skipping slow replicas.
- The current chart value shape supports these settings through component `extraArgs` maps.
- Storage capacity impact is accepted for the default resilient path; consumers can still override via chart values if needed.
- The MySQL pod/PDB mitigation is the earlier DS-11630 chart-level fix for the module-created singleton Grafana database.
- The live Grafana alert-rule database edits from DS-11630 are not persisted as raw MySQL mutations; alert rule behavior should be represented through Terraform alert resources.
