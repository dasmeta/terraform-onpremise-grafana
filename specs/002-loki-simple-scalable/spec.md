# Feature Specification: Loki SimpleScalable First-Class Support

**Feature Branch**: `002-loki-simple-scalable`  
**Created**: 2026-07-23  
**Status**: Draft  
**Input**: User description: "Add first-class Loki SimpleScalable support in terraform-onpremise-grafana (single PR)."

## Clarifications

### Session 2026-07-23

- Q: Should Distributed mode get full defaults in this release? → A: No; URL fallback to gateway only; full Distributed implementation is follow-up.
- Q: Should AWS wrapper and consumer repo version bumps be included? → A: No; separate follow-up PRs per original scope.
- Q: What Promtail collector changes are in scope? → A: Fix clients typo and mode-aware default push URL only; Alloy/Fluent Bit migration out of scope.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Logs visible in Grafana after SimpleScalable deploy (Priority: P1)

As a platform operator, I deploy Loki in SimpleScalable mode and Grafana shows logs without manually editing the Loki datasource URL.

**Why this priority**: Production logs were missing until operators manually pointed Grafana at the read service; this is the primary operational failure.

**Independent Test**: Deploy with `deploymentMode = SimpleScalable`, open Grafana Explore, query `{namespace="monitoring"}` and confirm log lines appear without any post-deploy datasource edits.

**Acceptance Scenarios**:

1. **Given** Loki is deployed in SimpleScalable mode, **When** Grafana stack is applied, **Then** the Loki datasource uses the read service endpoint for queries.
2. **Given** Promtail is enabled with default client settings, **When** pods emit logs, **Then** logs are pushed to the write service endpoint and become queryable via Grafana.

---

### User Story 2 - Safe SimpleScalable defaults and guardrails (Priority: P2)

As a module consumer, I get sensible SimpleScalable replica defaults and clear validation when configuration is incompatible with scalable mode.

**Why this priority**: Prevents misconfigured deployments that silently fail or run with zero read/write/backend pods.

**Independent Test**: Apply with SimpleScalable and no explicit replica counts; verify read=2, write=2, backend=1 in rendered Helm values. Apply with filesystem-only storage and SimpleScalable; verify Terraform fails with a clear error.

**Acceptance Scenarios**:

1. **Given** `deploymentMode = SimpleScalable` and read/write/backend replicas are not set, **When** the module renders Helm values, **Then** defaults are read=2, write=2, backend=1.
2. **Given** `deploymentMode = SimpleScalable` and storage is filesystem-only, **When** `terraform validate` runs, **Then** validation fails with a message requiring object storage.
3. **Given** user sets `write.replicas = 3`, **When** Helm values are rendered, **Then** write replicas remain 3 (user override preserved).

---

### User Story 3 - Documented migration and test coverage (Priority: P3)

As a module maintainer, I have documentation and an example test proving URL behavior and migration steps from SingleBinary to SimpleScalable.

**Why this priority**: Enables safe upgrades and regression prevention in CI.

**Independent Test**: Run `tests/loki-simple-scalable/` plan/validate and confirm documented URL matrix matches outputs; README migration section is present.

**Acceptance Scenarios**:

1. **Given** the README deployment modes section, **When** an operator follows SingleBinary → SimpleScalable migration steps, **Then** they can upgrade without manual datasource URL edits.
2. **Given** `tests/loki-simple-scalable/`, **When** terraform plan runs, **Then** SimpleScalable and SingleBinary query/push URLs match the documented matrix.

---

### Edge Cases

- What happens when `deploymentMode = SingleBinary`? URLs and behavior remain unchanged from current defaults.
- What happens when `promtail.clients` is explicitly set? User-provided clients override module defaults.
- What happens when storage is S3 in SimpleScalable mode? Schema object store and compactor delete request store align to S3 automatically unless user overrides.
- What happens for `deploymentMode = Distributed`? Query/push URLs fall back to gateway endpoints; full Distributed defaults remain out of scope for this release.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Module MUST set Grafana Loki datasource query URL to the read service when `deploymentMode = SimpleScalable`.
- **FR-002**: Module MUST set Promtail default push URL to the write service when `deploymentMode = SimpleScalable`.
- **FR-003**: Module MUST preserve SingleBinary URLs (`http://{release}.{namespace}.svc.cluster.local:3100`) when `deploymentMode = SingleBinary`.
- **FR-004**: Module MUST export `query_url` and `push_url` from the loki-stack submodule.
- **FR-005**: Module MUST fix the Promtail clients variable reference (`promtail.clients`, not `promtails.clients`).
- **FR-006**: When `deploymentMode = SimpleScalable` and component replicas are unset, module MUST default read=2, write=2, backend=1.
- **FR-007**: Module MUST validate `deploymentMode` is one of `SingleBinary`, `SimpleScalable`, or `Distributed`.
- **FR-008**: Module MUST reject SimpleScalable with filesystem-only storage at validate time.
- **FR-009**: For SimpleScalable with object storage, module MUST align `schemaConfig.object_store` and `compactor_options.delete_request_store` to the storage type.
- **FR-010**: Module MUST include `tests/loki-simple-scalable/` example and README covering deployment modes, URL matrix, and migration notes.

### Key Entities

- **Deployment mode**: Loki topology selection (`SingleBinary`, `SimpleScalable`, `Distributed`).
- **Query URL**: In-cluster endpoint Grafana uses for LogQL queries.
- **Push URL**: In-cluster endpoint Promtail uses for log ingestion.
- **Component replicas**: read, write, backend pod counts in SimpleScalable mode.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Operators deploying SimpleScalable see logs in Grafana on first query without manual datasource URL changes (0 manual URL edits required post-apply).
- **SC-002**: 100% of invalid SimpleScalable + filesystem configurations fail at `terraform validate` with an actionable error message.
- **SC-003**: Documented URL matrix in README matches terraform plan outputs for both SingleBinary and SimpleScalable in the example test.
- **SC-004**: SingleBinary consumers experience no URL or default behavior change when they do not set `deploymentMode`.

## Assumptions

- SimpleScalable deployments use object storage (S3 or equivalent); filesystem-only is acceptable only for SingleBinary.
- Distributed mode receives URL fallback only; full Distributed defaults are a follow-up.
- AWS wrapper (`dasmeta/grafanav12/aws`) pin bump and consumer repo version bumps are out of scope for this PR.
- Promtail remains the log collector; Alloy/Fluent Bit migration is out of scope.

## Out of Scope

- AWS wrapper `dasmeta/grafanav12/aws` pin bump
- payconomy `grafana.yaml` version bump
- Distributed mode full implementation beyond URL fallback
- Promtail → Alloy/Fluent Bit migration
