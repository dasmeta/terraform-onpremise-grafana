# Feature Specification: Default Service Alert Cleanup

**Feature Branch**: `002-alert-default-cleanup`  
**Created**: 2026-07-23  
**Status**: Draft  
**Input**: User description: "Clean up default module service alerts. Avoid HPA alerts for services without HPA, reduce noisy network alerts, stop tagging every alert as P1/critical, review DS-10938, and add deployment unavailable replicas > 0 for about 30s if suitable."

## Clarifications

### Session 2026-07-23

- Q: Should the whole DS-10938 monitoring request be added to default module alerts? A: No. Add only the generic reusable deployment unavailable replicas alert; keep Buycycle-specific route, Karpenter, EC2 credit, SSR, and ingress path alerts out of the default module.
- Q: What default threshold and pending period should unavailable replicas use? A: Alert when deployment unavailable replicas are greater than `0` for `30s`.
- Q: Should generated test fixtures and Spec Kit files remain in the change? A: Test fixture files were removed by request; Spec Kit files were restored by request.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Impact-Based Alert Labels (Priority: P1)

As an operator, I want default service alerts to carry priority and severity labels that match their operational impact so notification routing is not overloaded with false P1/critical signals.

**Why this priority**: Alert routing and escalation quality depend on correct labels.

**Independent Test**: Generate service alert rules and verify no-replica outage remains P1/critical while degradation alerts use warning-level labels.

**Acceptance Scenarios**:

1. **Given** a default service alert set, **When** no running replica alert rules are generated, **Then** those outage alerts keep P1/critical labels.
2. **Given** a default service alert set, **When** CPU, memory, replica state, HPA, restart, job, or unavailable replica alerts are generated, **Then** they use P2/warning labels unless explicitly overridden.
3. **Given** a caller provides alert-specific labels, **When** rules are generated, **Then** caller labels override module default labels.

---

### User Story 2 - Avoid HPA Alerts Without HPA Context (Priority: P1)

As an operator, I want HPA min/max alerts to be absent unless a service actually opts in or provides replica thresholds, so services without HPA do not produce invalid or noisy rules.

**Why this priority**: HPA alerts were being generated for all services and created noise for services without HPA.

**Independent Test**: Generate default service alert rules without HPA thresholds or explicit HPA enablement and verify no HPA min/max rules are present.

**Acceptance Scenarios**:

1. **Given** a service has default alert settings and no manual HPA threshold, **When** rules are generated, **Then** HPA min/max rules are not created.
2. **Given** a service explicitly enables HPA min/max alerts, **When** rules are generated, **Then** those HPA rules are created.
3. **Given** a service sets manual min/max thresholds, **When** rules are generated, **Then** replica min/max rules are created without requiring HPA metrics.

---

### User Story 3 - Reduce Default Network Alert Noise (Priority: P2)

As an operator, I want network anomaly alerts to be opt-in so default module adoption does not create noisy traffic alerts for every service.

**Why this priority**: Network anomaly alerts are useful for selected services but too noisy as default service-wide alerts.

**Independent Test**: Generate default service alert rules and verify network in/out anomaly rules are absent unless enabled.

**Acceptance Scenarios**:

1. **Given** a service uses default alert settings, **When** rules are generated, **Then** network in/out anomaly rules are not created.
2. **Given** a service explicitly enables network in/out alerts, **When** rules are generated, **Then** those rules are created with lower priority labels.

---

### User Story 4 - Alert on Deployment Unavailable Replicas (Priority: P2)

As an operator, I want a default deployment alert when unavailable replicas persist so rollout and capacity degradation is detected before a full outage.

**Why this priority**: DS-10938 identified unavailable replicas as a generic deployment health signal suitable for default module alerts.

**Independent Test**: Generate default service alert rules for a deployment and verify one unavailable replicas rule exists with threshold greater than `0` and pending period `30s`.

**Acceptance Scenarios**:

1. **Given** a deployment service uses default alert settings, **When** rules are generated, **Then** an unavailable replicas alert is created.
2. **Given** unavailable replicas are greater than `0` for `30s`, **When** Grafana evaluates the rule, **Then** the alert can fire as P2/warning.
3. **Given** the workload type is not `deployment`, **When** rules are generated, **Then** the deployment unavailable replicas alert is not created.

### Edge Cases

- Services without HPA metrics must not receive HPA-based rules unless explicitly enabled.
- Services without network alert opt-in must not receive network anomaly rules.
- Alert-specific labels must continue to override module-provided impact labels.
- Non-deployment workloads must not receive deployment-only unavailable replica rules.
- Buycycle-specific DS-10938 monitoring requirements must not leak into generic default module behavior.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The dashboard service alert wiring MUST stop forcing every generated service alert to P1.
- **FR-002**: The block service alert module MUST define default priority and severity labels per alert type.
- **FR-003**: No running replica outage alerts MUST remain P1/critical by default.
- **FR-004**: Resource, restart, job, replica state, HPA, and unavailable replica degradation alerts MUST default to P2/warning unless overridden.
- **FR-005**: Network anomaly alerts MUST default to P3/warning and MUST be disabled unless explicitly enabled.
- **FR-006**: HPA min/max replica alerts MUST be disabled by default unless explicitly enabled or a manual threshold is configured.
- **FR-007**: Manual min/max threshold support MUST continue to generate replica min/max alerts without requiring HPA metrics.
- **FR-008**: Deployment workloads MUST support a default unavailable replicas alert using unavailable replicas greater than `0` for `30s`.
- **FR-009**: The unavailable replicas alert MUST only be generated for deployment workloads.
- **FR-010**: Existing caller-provided label overrides MUST remain supported.
- **FR-011**: Module examples and generated documentation MUST describe the new defaults.

### Key Entities *(include if feature involves data)*

- **Alert Rule**: A generated Grafana rule with query, threshold, labels, annotations, and pending period.
- **Alert Type Label Defaults**: Module-owned priority and severity labels assigned by alert category.
- **Alert Opt-In Flag**: Per-alert enablement switch controlling noisy or context-dependent alert creation.
- **Workload Type**: Service workload category used to decide whether deployment-only alerts apply.
- **DS-10938 Generic Signal**: The reusable deployment unavailable replicas signal extracted from the broader Buycycle ticket.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Default service alert generation produces zero HPA min/max rules when no explicit HPA enablement or threshold is configured.
- **SC-002**: Default service alert generation produces zero network anomaly rules unless network alerts are explicitly enabled.
- **SC-003**: Generated default labels show no running replica alerts as P1/critical and degradation alerts as warning-level priorities.
- **SC-004**: Caller-provided alert labels override module alert type labels in generated rules.
- **SC-005**: Deployment default alert generation includes one unavailable replicas rule with equation `gt`, threshold `0`, and pending period `30s`.
- **SC-006**: Non-deployment workload default alert generation does not include a deployment unavailable replicas rule.

## Out of Scope

- Buycycle-specific route, SSR, ingress path, Karpenter, EC2 credit, and customer-specific latency alerts from DS-10938.
- Replacing `replicas_no`; full no-replica outage alerting remains separate from unavailable replica degradation alerting.
- Changes to Grafana notification policy routing outside label values supplied by generated rules.
- Adding durable CloudBrowser documentation or metric records for this code-only module change.

## Assumptions

- `kube-state-metrics` exposes `kube_deployment_status_replicas_unavailable` for deployment workloads.
- Existing module consumers can opt into HPA and network alerts where they need those signals.
- P1 should represent immediate or complete service outage by default, not every service degradation.
- The broader DS-10938 monitoring request should be split into service-specific follow-up work rather than generic defaults.
