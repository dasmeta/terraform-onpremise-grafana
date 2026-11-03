# Feature Specification: Tempo Service Map Integration

**Feature Branch**: `009-tempo-service-graph`
**Created**: 2026-11-03
**Status**: Approved
**Input**: Configure Grafana Tempo service map and node graph automatically when VictoriaMetrics is enabled, with optional service-graph metric dimensions, while always querying the selected metrics collector.

## User Scenarios & Testing

### User Story 1 - Explore Tempo service topology (Priority: P1)

An operator who enables both Tempo and VictoriaMetrics can open Grafana's built-in
Tempo datasource and explore a populated service map and node graph without
creating or maintaining a duplicate datasource.

**Why this priority**: The existing datasource already owns Tempo integration;
keeping one datasource prevents configuration drift and gives a usable service
topology view where metrics are available.

**Independent Test**: A native Terraform test verifies that a Tempo datasource
uses the selected metrics collector's UID for traces-to-metrics and service-map
queries and enables its node graph when both components are enabled.

**Acceptance Scenarios**:

1. **Given** Tempo and VictoriaMetrics are enabled, **When** the module plans,
   **Then** the existing `Tempo` datasource has `tracesToMetrics.datasourceUid`
   and `serviceMap.datasourceUid` set to `victoriametrics` and `nodeGraph.enabled`
   set to true, and Tempo enables the `service-graphs` and `span-metrics`
   metrics-generator processors.
2. **Given** Tempo is enabled and VictoriaMetrics is disabled, **When** the
   module plans, **Then** it retains the existing Tempo datasource behavior and
   does not emit a VictoriaMetrics service-map reference.
3. **Given** Tempo and VictoriaMetrics are enabled but `metrics_collector` is
   `"prometheus"`, **When** the module plans, **Then** Tempo writes and Grafana
   queries use `prometheus`, rather than the deployed-but-unselected
   VictoriaMetrics datasource.

---

### User Story 2 - Separate shared environments in service metrics (Priority: P2)

An operator whose Tempo instance receives traces from more than one deployment
environment can opt in to a bounded set of resource-attribute dimensions so
same-named services remain distinguishable in generated service-graph and
span-metrics series.

**Why this priority**: It avoids cross-environment topology collisions without
imposing additional metric labels on installations that do not need them.

**Independent Test**: A native Terraform test verifies that configured
dimensions are rendered in both Tempo metrics-generator processors and that an
omitted value adds no processor override.

**Acceptance Scenarios**:

1. **Given** `tempo.service_graph_dimensions = ["deployment.environment.name"]`,
   **When** the module plans, **Then** the Tempo Helm values apply that dimension
   to service-graph and span-metrics processors and enable client/server prefixes
   only for service-graph series.
2. **Given** `tempo.service_graph_dimensions` is omitted, **When** the module
   plans, **Then** the generated Tempo processor configuration is unchanged.

### Edge Cases

- Tempo disabled: no Tempo datasource or Tempo chart configuration is created.
- VictoriaMetrics disabled: the existing collector-selected traces-to-metrics
  datasource remains in use; no dangling `victoriametrics` UID is emitted.
- An empty dimensions list has the same effect as an omitted list.
- Consumers can retain their own chart values through `tempo.extra_configs`;
  the documented dimensions input is the module-owned, tested interface.

## Requirements

### Functional Requirements

- **FR-001**: When both Tempo and VictoriaMetrics are enabled, the module MUST
  configure the existing Tempo datasource—not create a second Tempo datasource—
  with the UID of the selected metrics collector for traces-to-metrics and
  service-map queries, and enable the node graph.
- **FR-002**: When VictoriaMetrics is disabled, the module MUST preserve the
  existing Tempo datasource configuration and must not refer to its UID.
- **FR-003**: The `tempo` input MUST expose an optional
  `service_graph_dimensions` list of strings, defaulting to an empty list.
- **FR-004**: Non-empty `service_graph_dimensions` MUST be rendered for both
  Tempo service-graph and span-metrics processors. Client/server prefixes MUST
  be enabled only for service-graph series, because Tempo does not support that
  setting for span metrics.
- **FR-005**: When both Tempo and VictoriaMetrics are enabled, the module MUST
  enable Tempo's `service-graphs` and `span-metrics` metrics-generator
  processors so the configured Grafana views receive their required series.
- **FR-006**: The module MUST add native Terraform regression tests for both
  datasource modes and both dimensions modes.
- **FR-007**: The README MUST document automatic VictoriaMetrics integration,
  the optional dimensions input, and its cardinality trade-off.
- **FR-008**: After the upstream module is released, the AWS wrapper MUST be
  updated in a separate PR to pin that release; no workspace-specific datasource
  configuration may be required.

## Success Criteria

### Measurable Outcomes

- **SC-001**: The regression test fails before the datasource integration is
  implemented and passes after it is implemented.
- **SC-002**: The regression test fails before the dimensions configuration is
  implemented and passes after it is implemented.
- **SC-003**: A plan with VictoriaMetrics disabled has no `serviceMap` object
  whose datasource UID is `victoriametrics`.
- **SC-004**: Formatting, initialization, validation, and the complete native
  Terraform test suite pass before the upstream PR is opened.

## Assumptions

- Tempo metrics are remote-written to the collector selected by
  `metrics_collector`; a deployed VictoriaMetrics backend is not necessarily
  the selected collector.
- `deployment.environment.name` is an OpenTelemetry resource attribute, but
  consumers opt in because metric-label cardinality is deployment-specific.
- The automatic processor activation is intentionally limited to configurations
  that enable both Tempo and VictoriaMetrics; it is necessary for the service
  map to produce metrics and may increase remote-write volume.
- The upstream release will be published before its AWS-wrapper dependency PR
  is opened.
