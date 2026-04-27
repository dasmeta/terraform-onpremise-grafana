# Feature Specification: Same-Cluster Multi-Environment Grafana Alert Routing

**Feature Branch**: `001-grafana-env-alert-routing`  
**Created**: 2026-04-17  
**Status**: Draft  
**Input**: User description: "Support multi-environment Grafana alert routing with per-environment channels across onprem and aws modules"

## Clarifications

### Session 2026-04-17

- Q: What should happen for alerts with no resolvable environment identity label? → A: Route unmatched alerts to a dedicated ops fallback channel and mark them as misconfigured.
- Q: Should environment routing be implemented as a dedicated input wrapper or by existing notification matchers? → A: Use existing `notifications.policies.matchers` and examples; do not add dedicated `environment_routing` input wrapper.
- Q: Should multi-environment routing validation modify the existing base test or use a dedicated test scenario? → A: Keep `tests/base` unchanged and add a separate multi-environment alert routing test scenario.
- Q: Should current ticket scope include multi-cluster central Grafana topology? → A: No; current ticket is same-cluster multi-namespace only, and multi-cluster central Grafana must be delivered in a separate follow-up ticket.

## User Scenarios & Testing *(mandatory)*

<!--
  IMPORTANT: User stories should be PRIORITIZED as user journeys ordered by importance.
  Each user story/journey must be INDEPENDENTLY TESTABLE - meaning if you implement just ONE of them,
  you should still have a viable MVP (Minimum Viable Product) that delivers value.

  Assign priorities (P1, P2, P3, etc.) to each story, where P1 is the most critical.
  Think of each story as a standalone slice of functionality that can be:
  - Developed independently
  - Tested independently
  - Deployed independently
  - Demonstrated to users independently
-->

### User Story 1 - Route alerts by environment label (Priority: P1)

As an operator, I can define environment-aware alert routing in Grafana so each environment sends alerts only to its own notification channel.

**Why this priority**: This is the core operational gap and the primary reason for this ticket.

**Independent Test**: Configure 3 environments with distinct channels, trigger one test alert per environment, and verify each alert is delivered only to its configured channel.

**Acceptance Scenarios**:

1. **Given** environment-aware routing is configured, **When** an alert is triggered with environment label `dev`, **Then** the alert is delivered only to the configured `dev` channel.
2. **Given** environment-aware routing is configured, **When** an alert is triggered with environment label `prod`, **Then** the alert is delivered only to the configured `prod` channel.

---

### User Story 2 - Support same-cluster multi-namespace topology (Priority: P2)

As an operator, I can use a single Grafana stack to monitor multiple environments deployed in one Kubernetes cluster by namespace while preserving environment-specific routing.

**Why this priority**: This is a common deployment model and must remain compatible with existing namespace-based dashboard and alert patterns.

**Independent Test**: Configure two namespaces representing two environments in one cluster, trigger alerts from each namespace, and verify routing and dashboard visibility are correct for both.

**Acceptance Scenarios**:

1. **Given** multiple namespaces are configured in one cluster, **When** service alerts are generated from each namespace, **Then** alerts are routed to the correct per-environment channels.

---

### Edge Cases

<!--
  ACTION REQUIRED: The content in this section represents placeholders.
  Fill them out with the right edge cases.
-->

- What happens when an alert has no resolvable environment identity label?
- How does routing behave when an environment is configured without a notification channel?
- How does routing behave when an environment is present in dashboards but missing from routing map?

## Requirements *(mandatory)*

<!--
  ACTION REQUIRED: The content in this section represents placeholders.
  Fill them out with the right functional requirements.
-->

### Functional Requirements

- **FR-001**: The module MUST support consolidated multi-environment dashboard and alerting operation in a shared Grafana stack.
- **FR-002**: The module MUST support environment-aware alert routing so each environment can be mapped to its own notification channel using existing notification policy matchers.
- **FR-003**: The module MUST support deriving or assigning environment identity for same-cluster deployments where environments are separated by namespace.
- **FR-004**: The module MUST include reference configuration for same-cluster multi-namespace topology.
- **FR-006**: Existing namespace-variable dashboard behavior for consolidated views MUST remain functional after the routing enhancement.
- **FR-007**: Equivalent capability and examples MUST be synchronized in `dasmeta/terraform-aws-grafanav12` in the same delivery scope.
- **FR-008**: Routing behavior MUST include a safe and explicit behavior for alerts missing environment identity so silent cross-environment routing cannot occur, implemented through policy matcher and fallback contact point configuration.
- **FR-009**: The feature MUST provide a validation path that proves for 3 or more environments: correct routing per environment and negative isolation checks (env A does not reach env B channel).
- **FR-010**: Alerts with missing or unresolved environment identity MUST be routed to a dedicated `ops-fallback` channel and marked as misconfigured by notification policy configuration and documented examples.
- **FR-011**: Test coverage for multi-environment alert routing MUST be implemented in a dedicated same-cluster test scenario and MUST NOT repurpose or alter the existing `tests/base` behavior.

### Key Entities *(include if feature involves data)*

- **Environment Routing Identity**: A canonical environment marker used for alert routing decisions, derived from namespace, datasource context, or explicit mapping.
- **Environment Channel Mapping**: Configuration that maps one environment identity to one or more notification channels.
- **Topology Mode**: Deployment mode definition for same-cluster namespace-based environment separation in this ticket.
- **Routing Policy Rule**: Rule set that matches environment identity labels and dispatches alerts to target channels.

## Success Criteria *(mandatory)*

<!--
  ACTION REQUIRED: Define measurable success criteria.
  These must be technology-agnostic and measurable.
-->

### Measurable Outcomes

- **SC-001**: In a validation run with at least 3 environments, 100% of test alerts are delivered only to each alert's configured environment channel.
- **SC-002**: In the same validation run, 0 alerts are delivered to a non-matching environment channel.
- **SC-003**: Same-cluster multi-namespace topology is validated with successful per-environment routing behavior.
- **SC-004**: Consolidated dashboard functionality remains available for all configured environments after the change.
- **SC-005**: In validation, 100% of unmatched-environment alerts are delivered to `ops-fallback` and do not reach any environment-specific channel.

## Out of Scope

- Rewriting dashboard or alert semantics beyond what is needed for environment-aware routing.
- Changing application metrics, logs, or traces schema.
- Adding unrelated new alert rules.
- Provisioning new Kubernetes clusters.
- Redesigning the broader non-Grafana observability architecture.
- Multi-cluster central Grafana setup with external datasources from other clusters (tracked in a separate follow-up ticket).

## Assumptions

<!--
  ACTION REQUIRED: The content in this section represents placeholders.
  Fill them out with the right assumptions based on reasonable defaults
  chosen when the feature description did not specify certain details.
-->

- Grafana alert routing can evaluate an environment identity label for same-cluster namespace-based environments.
- Existing module consumers can adopt new routing inputs without mandatory redesign of unrelated observability components.
