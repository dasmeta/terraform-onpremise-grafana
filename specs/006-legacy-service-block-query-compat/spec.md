# Feature Specification: Preserve Deployed Service-Block Query Contracts

**Feature Branch**: `006-legacy-service-block-query-compat`
**Created**: 2026-10-15
**Status**: Approved design
**Input**: Preserve an existing application dashboard's deployed service-panel and service-alert query contracts, without changing modern defaults.

## User Scenarios & Testing

### User Story 1 - Preserve the Existing Application Dashboard (Priority: P1)

As a platform operator, I can enable service-block compatibility on an existing application dashboard so a module upgrade does not alter its service status panels or service alert rules.

**Why this priority**: The production plan must not rewrite already-approved Grafana dashboard and alert-rule definitions.

**Independent Test**: Plan a dashboard containing a service block with compatibility enabled and assert the exact deployed status-panel and alert expressions.

**Acceptance Scenarios**:

1. **Given** `legacy_service_block_queries` is enabled, **when** service block panels are generated, **then** the phase status expressions use `pod=~"<service>-.*"`.
2. **Given** the setting is enabled, **when** service alerts are generated, **then** the phase alert uses the deployed legacy matcher and the memory alert uses `container_memory_usage_bytes`.

---

### User Story 2 - Keep Modern Defaults (Priority: P2)

As a platform operator, I can omit the setting and retain the module's current modern status selectors and working-set memory metric.

**Why this priority**: Compatibility is migration-only and must not change new or unconfigured dashboards.

**Independent Test**: Plan the same service block without the setting and assert the current modern selector and metric.

**Acceptance Scenarios**:

1. **Given** the setting is absent or false, **when** service block panels and alerts are generated, **then** their modern expressions remain unchanged.

### Edge Cases

- The parent `legacy_dashboard_queries` setting remains independent: it preserves the already-supported widget contracts but does not silently enable the service-block contract.
- Multiple dashboards may choose different compatibility values without affecting one another.
- Service alert metadata, thresholds, pause state, layout, and resource addresses remain unchanged.

## Requirements

### Functional Requirements

- **FR-001**: The dashboard `defaults.query_compatibility` object MUST support the optional boolean `legacy_service_block_queries`, defaulting to `false`.
- **FR-002**: When enabled, service-block status panels MUST render the deployed `pod=~"<service>-.*"` expressions.
- **FR-003**: When enabled, service-block phase alerts MUST render `^<service>(-[^-]+)?-[^-]+$` and memory alerts MUST use `container_memory_usage_bytes`.
- **FR-004**: When absent or false, every service-block query and alert expression MUST retain its v1.31.0 behavior.
- **FR-005**: The implementation MUST be dashboard-scoped and MUST NOT alter unrelated dashboard, alert, layout, or state-address behavior.
- **FR-006**: Documentation MUST identify this as an upgrade-only, opt-in compatibility control and state that its default is false.
- **FR-007**: Native Terraform tests MUST verify both compatibility and default contracts.

### Key Entities

- **Service-block query compatibility**: Per-application-dashboard selection that controls only service status-panel and service-alert query rendering.
- **Deployed query contract**: Exact PromQL expressions presently stored in an existing Grafana deployment and confirmed by the recorded plan.

## Success Criteria

### Measurable Outcomes

- **SC-001**: With both compatibility selections enabled, the next Terraform plan has zero changes to the existing application dashboard and its nested service alert rule groups.
- **SC-002**: Test coverage asserts all three migrated service query forms: dashboard phase status, alert phase status, and alert memory metric.
- **SC-003**: The compatibility-disabled test asserts the current v1.31.0 expressions exactly.

## Assumptions

- The recorded plan is the authoritative production-state comparison: it shows 16 service-status panel expression changes and two service-alert expression changes.
- A consumer will select the new option only after the released on-premise module and AWS wrapper are available.
- This addition is backward compatible because it is opt-in and defaults to false.
