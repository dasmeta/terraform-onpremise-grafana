# Feature Specification: Prevent Duplicate kube-state-metrics Annotation Scrapes

**Feature Branch**: `007-kube-state-scrape`  
**Created**: 2026-10-16  
**Status**: Approved for implementation  
**Input**: Prevent the legacy annotation job from duplicating the standalone kube-state-metrics ServiceMonitor scrape.

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

### User Story 1 - Scrape kube-state-metrics Once (Priority: P1)

As a platform operator, I can install the standalone kube-state-metrics release
without it being scraped a second time by Prometheus' legacy annotation-based
service discovery job.

**Why this priority**: The duplicate job can scrape the service root instead
of `/metrics`, producing persistent failed targets even though the
ServiceMonitor is healthy.

**Independent Test**: Plan the kube-state-metrics child module and inspect its
Helm values: the ServiceMonitor is enabled and the Service is opted out of
annotation discovery.

**Acceptance Scenarios**:

1. **Given** Prometheus is the active collector, **when** the standalone
   kube-state-metrics release is rendered, **then** its ServiceMonitor remains
   enabled and selected by the Prometheus release label.
2. **Given** the legacy annotation scrape job is enabled elsewhere in the
   stack, **when** the kube-state-metrics Service is rendered, **then** it has
   `prometheus.io/scrape: "false"` and is not discovered by that job.

---

[Add more user stories as needed, each with an assigned priority]

### Edge Cases

- Consumer-provided Service annotations must not re-enable the annotation
  scrape, because doing so recreates the duplicate target.
- The change must not disable the chart's Prometheus ServiceMonitor or alter
  its port, selector, metric relabeling, collector allowlist, or service name.
- VictoriaMetrics mode retains its existing collector-specific behavior and is
  outside this Prometheus ServiceMonitor fix.

## Requirements *(mandatory)*

<!--
  ACTION REQUIRED: The content in this section represents placeholders.
  Fill them out with the right functional requirements.
-->

### Functional Requirements

- **FR-001**: The standalone kube-state-metrics Service MUST set
  `prometheus.io/scrape` to the string value `"false"` in module-owned Helm
  values.
- **FR-002**: The module MUST retain its current enabled Prometheus
  ServiceMonitor configuration, including the Prometheus release selector.
- **FR-003**: Module-owned service values MUST take precedence over
  `extra_configs`, so a consumer cannot accidentally recreate the known
  duplicate scrape path.
- **FR-004**: Native Terraform tests MUST assert both the disabled annotation
  scrape and enabled ServiceMonitor contract.
- **FR-005**: Module documentation MUST explain that kube-state-metrics uses a
  ServiceMonitor rather than annotation discovery in Prometheus mode.

### Key Entities

- **Standalone kube-state-metrics Service**: Kubernetes Service installed by
  the child Helm release, exposing the exporter on port 8080.
- **Prometheus ServiceMonitor**: The operator custom resource that discovers
  the standalone Service through its stable labels and scrapes `/metrics`.
- **Legacy annotation scrape job**: An optional service-discovery job which
  selects Services based on `prometheus.io/scrape`; it must not select this
  Service.

## Success Criteria *(mandatory)*

<!--
  ACTION REQUIRED: Define measurable success criteria.
  These must be technology-agnostic and measurable.
-->

### Measurable Outcomes

- **SC-001**: A rendered standalone kube-state-metrics release contains
  `service.annotations["prometheus.io/scrape"] == "false"`.
- **SC-002**: The same rendered release retains
  `prometheus.monitor.enabled == true` when the Prometheus collector is active.
- **SC-003**: The focused native test passes before release.

## Assumptions

- The parent Prometheus module may retain the legacy annotation job for
  unrelated workloads, so changing that job is out of scope.
- The kube-state-metrics Helm chart accepts `service.annotations` values.
- This is a backward-compatible bug fix: the ServiceMonitor is already the
  intended owner of kube-state-metrics scraping.
