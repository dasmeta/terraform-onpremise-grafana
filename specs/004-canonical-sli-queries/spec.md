# Feature Specification: Canonical MSP Uptime and Latency

**Feature Branch**: `fix/msp-sli-queries`
**Created**: 2026-09-22
**Status**: Approved
**Input**: Correct the SLA/SLO dashboard and alert calculations for uptime and latency, and define the same two indicators for the account KPI collector without adding metrics.

## User Scenarios & Testing

### User Story 1 - Trust the SLA/SLO dashboard (Priority: P1)

As an MSP operator, I need dashboard uptime and latency values to describe the production service consistently so I can report them to customers.

**Why this priority**: Incorrect or differently weighted values can produce contradictory customer reports.

**Independent Test**: Render the two non-histogram widgets for an ingress scope and verify the uptime value represents successful requests divided by all requests and latency represents total successful-request duration divided by the number of successful requests.

**Acceptance Scenarios**:

1. **Given** a scoped set of requests containing 2xx, 3xx, 4xx, 499, and 5xx statuses, **When** uptime is calculated, **Then** only 5xx responses reduce uptime and all requests remain in the denominator.
2. **Given** successful requests with different traffic volumes and durations, **When** latency is calculated, **Then** it is weighted by request count and expressed in seconds.
3. **Given** no matching traffic, **When** either indicator is calculated, **Then** the dashboard reports no input data instead of inventing a successful value.

---

### User Story 2 - Receive alerts with the same semantics (Priority: P2)

As an MSP operator, I need the ingress availability and latency alerts to use the same status and weighting rules as the dashboard.

**Why this priority**: An alert must not disagree with the panel used to investigate it.

**Independent Test**: Generate both alert definitions with and without an additional metric scope and verify that each expression is valid and follows the dashboard definitions.

**Acceptance Scenarios**:

1. **Given** an empty additional scope, **When** alert expressions are generated, **Then** no dangling label separator is present.
2. **Given** a customer-specific scope, **When** alert expressions are generated, **Then** it is applied to numerator and denominator.
3. **Given** a latency alert, **When** annotations are generated, **Then** latency threshold and latency annotations are used rather than availability settings.

### Edge Cases

- Empty metric filters must still produce valid selectors.
- HTTP 499 remains visible in total traffic but is not a provider-side failure by default.
- Histogram panels keep their distribution behavior while using the selected period and successful-response scope for latency.
- A zero denominator must produce no data, not 0% or 100%.

## Requirements

### Functional Requirements

- **FR-001**: The uptime indicator MUST equal non-5xx requests divided by all scoped requests, multiplied by 100.
- **FR-002**: The latency indicator MUST equal total observed duration divided by request count for scoped 2xx and 3xx responses.
- **FR-003**: Dashboard calculations MUST honor the configured observation period instead of a hard-coded period.
- **FR-004**: Dashboard latency MUST be displayed in seconds and MUST NOT be labeled as a percentage.
- **FR-005**: Availability and latency alerts MUST use the same success and failure classifications as the dashboard.
- **FR-006**: Additional metric scoping MUST be applied consistently and MUST be optional.
- **FR-007**: No new KPI types or customer-specific identifiers may be introduced.
- **FR-008**: Automated contract tests MUST cover default and filtered expressions, display units, and alert annotations.

## Success Criteria

### Measurable Outcomes

- **SC-001**: All four uptime/latency dashboard and alert expressions pass automated contract tests.
- **SC-002**: The same request sample produces matching uptime and average-latency semantics in panels and alerts.
- **SC-003**: Empty and non-empty metric scopes both produce syntactically complete expressions in 100% of contract cases.
- **SC-004**: Existing histogram mode remains available and no metric beyond uptime and latency is added.

## Assumptions

- NGINX ingress controller request counters and duration sum/count series are available in the selected data source.
- Provider-caused unavailability is represented by HTTP 5xx; HTTP 499 is customer/request cancellation unless a separate customer contract states otherwise.
- Successful latency is measured over 2xx and 3xx responses.
- The default reporting/dashboard period remains one day, but callers may select another period.
