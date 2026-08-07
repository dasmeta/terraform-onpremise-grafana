# Feature Specification: MSK CloudWatch Monitoring

**Feature Branch**: `004-msk-monitoring`  
**Created**: 2026-08-07  
**Status**: Draft  
**Input**: User description: "Add MSK (AWS Kafka) CloudWatch monitoring to terraform-onpremise-grafana. Scope: new MSK dashboard widgets using AWS/Kafka CloudWatch metrics (CPU, memory, bytes in/out, partition counts, offline partitions, consumer lag if applicable); new block/msk dashboard block; wire block into dashboard module; optional MSK CloudWatch-based Grafana alerts; tests and README/docs updates. Jira: DMVP-10260."

## Clarifications

### Session 2026-08-07

- Q: Should RDS monitoring be included? → A: No; MSK only. RDS is out of scope.
- Q: Are MSK CloudWatch alerts required in the first release? → A: Optional; deliver dashboard monitoring as P1 and treat alerting as a configurable P2 increment when required by the ticket.
- Q: Should consumer-repo CloudWatch datasource setup be included? → A: No; consumers configure CloudWatch access separately.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - MSK Dashboard Monitoring (Priority: P1)

As a platform operator, I want a reusable MSK monitoring dashboard block so I can observe Kafka cluster health in Grafana without hand-building CloudWatch panels for every environment.

**Why this priority**: MSK is a critical messaging backbone; missing visibility delays incident detection for throughput drops, broker stress, and partition problems.

**Independent Test**: Enable the MSK dashboard block with a cluster identifier and confirm Grafana shows broker health, throughput, and partition status panels using CloudWatch data.

**Acceptance Scenarios**:

1. **Given** a configured MSK cluster identifier, **When** the dashboard module is applied, **Then** a dashboard block displays MSK health and throughput metrics.
2. **Given** standard AWS/Kafka CloudWatch metrics are available, **When** an operator opens the MSK block, **Then** they can see CPU utilization, memory usage, bytes in, and bytes out for the cluster.
3. **Given** partition-related metrics are available, **When** an operator views the MSK block, **Then** they can see partition count and offline partition indicators.
4. **Given** consumer lag metrics are published for the cluster, **When** an operator views the MSK block, **Then** lag visibility is available without custom panel authoring.
5. **Given** multiple MSK clusters are configured, **When** the dashboard is rendered, **Then** each configured cluster appears as a distinct monitored target within the block layout.

---

### User Story 2 - Optional MSK Alerting (Priority: P2)

As an on-call operator, I want optional MSK alert rules for critical Kafka conditions so I am notified before message processing is severely impacted.

**Why this priority**: Dashboards enable investigation; alerts reduce time-to-detect for broker failures and partition outages. This is secondary to baseline visibility.

**Independent Test**: Enable MSK alert configuration for a cluster and verify alert rules are generated for critical conditions such as offline partitions or sustained high broker resource usage.

**Acceptance Scenarios**:

1. **Given** MSK alerting is enabled, **When** alert rules are generated, **Then** at least one alert covers offline partitions greater than zero.
2. **Given** MSK alerting is enabled, **When** alert rules are generated, **Then** operators can route alerts using standard labels suitable for notification policies.
3. **Given** MSK alerting is disabled, **When** the module is applied, **Then** no MSK-specific alert rules are created.
4. **Given** custom thresholds are provided, **When** alert rules are generated, **Then** the configured thresholds are reflected in the generated rules.

---

### User Story 3 - Consumer Documentation And Examples (Priority: P3)

As a module consumer, I want clear examples and documentation for MSK monitoring so I can adopt the feature quickly and consistently across environments.

**Why this priority**: Reusable module value depends on predictable configuration and low onboarding effort.

**Independent Test**: Follow the documented example configuration and verify the MSK dashboard block renders with generic placeholder cluster identifiers and no client-specific hardcoding.

**Acceptance Scenarios**:

1. **Given** module documentation, **When** a consumer follows the MSK example, **Then** they can add MSK monitoring to an application dashboard without reading module internals.
2. **Given** example configurations, **When** reviewed, **Then** they use generic cluster identifiers and contain no client-specific names.
3. **Given** the feature is complete, **When** validation runs, **Then** module examples and documentation reflect the MSK block inputs and expected outcomes.

### Edge Cases

- CloudWatch metrics may be absent when enhanced monitoring is disabled or permissions are incomplete; panels should degrade gracefully and preserve configurable no-data behavior where alerts are used.
- Some MSK deployments may not expose consumer lag metrics; lag panels should be optional or omitted when lag metrics are unavailable.
- Multi-broker clusters may require aggregation across brokers; the block must remain readable when one or more brokers stop reporting temporarily.
- Global module outputs must not embed client-specific cluster names, account IDs, or environment-specific routing rules.
- Existing dashboard blocks and custom rows configured by consumers must continue to work unchanged when MSK monitoring is not enabled.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The module MUST provide a reusable MSK monitoring dashboard block for AWS Managed Streaming for Apache Kafka clusters.
- **FR-002**: The MSK dashboard block MUST surface broker resource utilization including CPU and memory usage.
- **FR-003**: The MSK dashboard block MUST surface throughput signals including bytes in and bytes out.
- **FR-004**: The MSK dashboard block MUST surface partition health signals including total partition count and offline partition count.
- **FR-005**: The MSK dashboard block MUST support consumer lag visibility when lag metrics are available for the configured cluster.
- **FR-006**: Consumers MUST be able to configure one or more MSK cluster identifiers for monitoring.
- **FR-007**: Consumers MUST be able to override region, time aggregation period, and CloudWatch datasource selection for MSK panels.
- **FR-008**: The module MUST allow MSK alerting to be enabled or disabled independently of the dashboard block.
- **FR-009**: When MSK alerting is enabled, the module MUST provide alert coverage for offline partitions greater than zero by default.
- **FR-010**: When MSK alerting is enabled, consumers MUST be able to override thresholds, pending duration, labels, and annotations.
- **FR-011**: Generated MSK monitoring configuration MUST avoid client-specific cluster names, accounts, or routing identifiers by default.
- **FR-012**: The module MUST include examples and documentation showing how to enable MSK monitoring.
- **FR-013**: Existing non-MSK dashboard and alert behavior MUST remain unchanged when MSK monitoring is not configured.

### Key Entities

- **MSK Cluster Target**: A Kafka cluster selected for monitoring, identified by its CloudWatch dimension value.
- **MSK Dashboard Block**: A grouped set of MSK health, throughput, partition, and optional lag panels for one or more cluster targets.
- **MSK Alert Configuration**: Optional settings that enable, scope, and tune MSK alert rules for critical conditions.
- **CloudWatch Datasource Reference**: The monitoring data source used by MSK panels and optional alerts.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: An operator can add MSK monitoring to a dashboard in one configuration step without creating custom panels manually.
- **SC-002**: At least four MSK health categories are visible in the dashboard block: resource utilization, throughput, partition status, and optional lag.
- **SC-003**: A consumer can monitor multiple MSK clusters from the same dashboard block configuration.
- **SC-004**: When MSK alerting is enabled, offline partition conditions produce an alertable rule without additional custom rule authoring.
- **SC-005**: Documentation and examples allow a new consumer to enable MSK monitoring in under 15 minutes.
- **SC-006**: No client-specific identifiers appear in default MSK examples or generated baseline configuration.

## Assumptions

- Consumers already have a working CloudWatch datasource in Grafana with permissions to read AWS/Kafka metrics.
- Standard MSK enhanced monitoring metrics are available for target clusters in the configured AWS region.
- Offline partitions and broker resource metrics are sufficient defaults for initial operational visibility.
- Alert delivery paths remain configured by consumers through existing notification policies and contact points.
- RDS and other database monitoring are explicitly excluded from this feature.

## Out of Scope

- RDS monitoring or changes to existing RDS dashboard blocks.
- Provisioning or IAM configuration for CloudWatch datasource access in consumer environments.
- Changes to AWS wrapper or external consumer repositories.
- Client-specific cluster naming, routing, or notification integration.
- Migration of existing manually authored MSK dashboards outside this module.
- Kafka Connect, Schema Registry, or non-MSK self-managed Kafka deployments unless they expose equivalent AWS/Kafka CloudWatch metrics without custom integration work.

## Dependencies

- Existing CloudWatch-based dashboard widget patterns used elsewhere in the module.
- Grafana CloudWatch datasource availability in the target environment.
- DMVP-10260 acceptance depends on validating MSK visibility and, if enabled, alert behavior in a consumer environment after module release.
