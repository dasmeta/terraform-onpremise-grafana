# Feature Specification: Preserve Existing Dashboard Queries

**Feature Branch**: `feat/legacy-dashboard-query-compat`

**Created**: 2026-10-13

**Status**: Draft

**Input**: User description: "Keep the current Grafana dashboard as it is while allowing the Grafana module to retain its newer default queries."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Preserve a Production Dashboard (Priority: P1)

As a platform operator, I can explicitly select compatibility mode for an existing dashboard so its displayed container and pod data continues to use the query behaviour already deployed in production.

**Why this priority**: The production dashboard must remain visually and functionally unchanged during the monitoring-stack upgrade.

**Independent Test**: Enable compatibility mode for a representative existing dashboard and compare its generated dashboard queries with the recorded production query contract.

**Acceptance Scenarios**:

1. **Given** an existing dashboard is configured for compatibility, **When** its definition is generated, **Then** every affected container and pod query matches the legacy query contract.
2. **Given** compatibility is configured for one dashboard, **When** another dashboard is generated without compatibility, **Then** the other dashboard retains the current default query behaviour.

---

### User Story 2 - Keep Modern Defaults for New Dashboards (Priority: P2)

As a platform operator, I can create or update dashboards without opting in to compatibility and receive the current query behaviour.

**Why this priority**: Compatibility must not prevent improvements from being the default for new work.

**Independent Test**: Generate a dashboard without the compatibility selection and verify it matches the current baseline dashboard contract.

**Acceptance Scenarios**:

1. **Given** no compatibility setting is supplied, **When** a dashboard is generated, **Then** its queries match the current baseline behaviour.

---

### User Story 3 - Apply Compatibility Predictably (Priority: P3)

As a platform operator, I can identify exactly which dashboard query families compatibility preserves and know that alert rules are outside this setting's scope.

**Why this priority**: A bounded option prevents unexpected preservation of obsolete behaviour in unrelated monitoring resources.

**Independent Test**: Review the published compatibility contract and generate dashboard and alert resources with compatibility enabled.

**Acceptance Scenarios**:

1. **Given** compatibility is enabled, **When** dashboard resources are generated, **Then** only documented container and pod dashboard query families use legacy behaviour.
2. **Given** compatibility is enabled, **When** alert rules are generated, **Then** their behaviour is unaffected by the dashboard compatibility setting.

### Edge Cases

- A dashboard omits the compatibility setting: it must use the modern default without an error.
- A dashboard has compatibility enabled but does not include an affected query family: generation must succeed with no unrelated changes.
- Multiple dashboards use different compatibility selections: each dashboard must retain its own selected behaviour.
- Existing alert pause settings must retain their current behaviour irrespective of dashboard compatibility.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST provide an explicit, dashboard-scoped compatibility selection for preserving legacy dashboard query behaviour.
- **FR-002**: When the compatibility selection is enabled, the system MUST preserve the recorded legacy query contract for every affected container-memory, ingress-memory, pod-memory, container-network, container-network-traffic, container-network-error, container-replica, pod-CPU, and pod-restart dashboard query.
- **FR-003**: When the compatibility selection is absent or disabled, the system MUST retain the current query behaviour.
- **FR-004**: The compatibility selection MUST apply independently to each dashboard.
- **FR-005**: The compatibility selection MUST NOT change alert rules, alert pause state, dashboard layout, titles, permissions, or unrelated dashboard queries.
- **FR-006**: The system MUST document the selection, its default, the affected query families, and its exclusion of alert rules.
- **FR-007**: The system MUST provide automated coverage demonstrating both legacy-compatible and modern-default dashboard outputs.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A dashboard with compatibility enabled has zero differences from the approved legacy query contract across 100% of affected query expressions.
- **SC-002**: A dashboard without compatibility enabled has zero differences from the approved current query contract across 100% of affected query expressions.
- **SC-003**: In a test configuration containing two dashboards with opposing selections, 100% of affected queries follow the selection of their own dashboard.
- **SC-004**: Enabling compatibility produces zero changes to alert-rule outputs in automated verification.

## Assumptions

- The production dashboard query contract captured from the current deployment is the authoritative legacy baseline.
- Compatibility is required only for dashboard queries; alert corrections remain independently manageable.
- Modern query behaviour remains the default to avoid carrying legacy behaviour into new dashboards.
- The feature will be released through the existing Grafana module and wrapper release process before it is selected by a consumer environment.
