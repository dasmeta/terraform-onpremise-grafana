# Feature Specification: Global Disk Capacity Alerts

**Feature Branch**: `002-alert-default-cleanup`
**Created**: 2026-07-23
**Status**: Draft
**Input**: User description: "Refine disk alerting globally, not for a specific client. Determine whether disk alerts are needed and, if yes, implement them for everyone. Use VictoriaMetrics for the disk alert datasource when available while keeping dashboard behavior unchanged."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Default PVC Disk Alert (Priority: P1)

As an operator using this Grafana stack module, I want a reusable disk-capacity alert for persistent volumes so storage exhaustion is detected before a workload fails.

**Why this priority**: Disk-full incidents are generic infrastructure risks across clients and workloads. A module-level alert prevents every consumer from having to rediscover and hand-code the same capacity check.

**Independent Test**: Instantiate the module with default alert settings and verify a PVC disk-capacity alert is generated with a threshold greater than 90% and no client-specific matchers.

**Acceptance Scenarios**:

1. **Given** default alert settings, **When** alert rules are generated, **Then** the generated rules include a global PVC disk usage alert.
2. **Given** any namespace or PVC name, **When** the default disk alert evaluates, **Then** it can match the PVC without requiring client-specific names.
3. **Given** VictoriaMetrics is enabled, **When** the disk alert rule is generated, **Then** the rule uses the VictoriaMetrics datasource UID unless explicitly overridden.

---

### User Story 2 - Safe Override And Disable Path (Priority: P2)

As a module consumer, I want to tune or disable the default disk alert when my environment needs a different threshold, datasource, or scope.

**Why this priority**: Global defaults should reduce missing coverage without forcing every consumer into one fixed policy.

**Independent Test**: Configure the disk alert input with custom threshold, pending period, datasource, namespace regex, and PVC regex values and verify the generated rule reflects those overrides.

**Acceptance Scenarios**:

1. **Given** the disk alert is disabled, **When** alert rules are generated, **Then** no default PVC disk alert is included.
2. **Given** custom threshold or matcher values, **When** alert rules are generated, **Then** the generated expression and metadata reflect those custom values.

### Edge Cases

- VictoriaMetrics may be disabled in some module deployments; the alert should fall back to the Prometheus datasource rather than referencing a missing UID.
- Some clusters may not expose kubelet volume stats; the alert should preserve configurable no-data and execution-error behavior.
- Global alerting must not introduce client-specific names, hostnames, namespaces, or PVC identifiers.
- Caller-provided custom alert rules must continue to be preserved alongside module-provided default rules.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The module MUST provide a default global PVC disk-capacity alert.
- **FR-002**: The default alert MUST use the expression pattern `100 * used_bytes / capacity_bytes` over `kubelet_volume_stats_used_bytes` and `kubelet_volume_stats_capacity_bytes`.
- **FR-003**: The default alert MUST alert when usage is greater than `90` by default.
- **FR-004**: The default alert MUST use VictoriaMetrics datasource UID `victoriametrics` when VictoriaMetrics is enabled.
- **FR-005**: The default alert MUST fall back to Prometheus datasource UID `prometheus` when VictoriaMetrics is not enabled.
- **FR-006**: Consumers MUST be able to disable the default disk alert.
- **FR-007**: Consumers MUST be able to override threshold, pending period, datasource UID, namespace regex, PVC regex, labels, annotations, and no-data/error states.
- **FR-008**: Existing custom alert rules MUST continue to be included together with the default disk alert.
- **FR-009**: The alert MUST include generic labels and annotations suitable for routing and notification templates.
- **FR-010**: New Terraform examples and documentation MUST avoid client-specific names.

### Key Entities

- **Default Disk Alert**: A generated Grafana alert rule that evaluates PVC usage percentage across matching namespaces and PVCs.
- **Disk Alert Configuration**: Optional module input used to enable, disable, scope, and tune the default disk alert.
- **Datasource Selection**: Rule-level configuration that chooses `victoriametrics` when enabled, falls back to `prometheus`, and can be overridden per disk alert.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A default module plan includes one generic PVC disk-capacity alert rule.
- **SC-002**: The generated alert expression contains no client-specific namespace or PVC names by default.
- **SC-003**: The generated alert uses `victoriametrics` when VictoriaMetrics is enabled and `prometheus` when it is disabled.
- **SC-004**: A consumer can disable the default disk alert without affecting custom alert rules.
- **SC-005**: Terraform formatting and validation pass for the changed module and new example.

## Assumptions

- `kubelet_volume_stats_used_bytes` and `kubelet_volume_stats_capacity_bytes` are available through the Prometheus-compatible datasource.
- A threshold greater than 90% is the appropriate global default for capacity exhaustion risk.
- The existing alert module remains the right Grafana rule-generation path.
- Service Desk routing is supplied by notification policies and contact points configured by consumers, while this feature provides route-friendly labels.

## Out of Scope

- Client-specific ClickHouse, GameBit, Chipsy, or Backoffice matchers.
- Creating external contact points or secrets for any specific Service Desk integration.
- Changing dashboard JSON, dashboard queries, or default application dashboard datasources.
- Changing existing dashboard service-block alert semantics.
- Creating CloudBrowser task or ownership records; available CB tools in this session do not expose a task/document search or write path for this code-only module change.
