# Tasks: Default Service Alert Cleanup

**Input**: Design documents from `specs/002-alert-default-cleanup/`  
**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`

**Tests**: Terraform formatting and validation are required. Dedicated fixture files are not part of the restored Spec Kit artifact set because they were removed by user request.

**Organization**: Tasks are grouped by user story for independent delivery and review.

## Phase 1: Setup

- [x] T001 Confirm feature branch `002-alert-default-cleanup` and alert cleanup scope
- [x] T002 Review existing default alert generation in `modules/dashboard/alerts.tf` and `modules/dashboard/modules/alerts/block-service/`
- [x] T003 [P] Review DS-10938/DMVP-10113 scope and separate generic default-module signals from service-specific monitoring

---

## Phase 2: Foundational

- [x] T004 Define per-alert default label map in `modules/dashboard/modules/alerts/block-service/locals.tf`
- [x] T005 Remove dashboard-level forced P1 label from `modules/dashboard/alerts.tf`
- [x] T006 Preserve label override order in `modules/dashboard/modules/alerts/block-service/outputs.tf`

---

## Phase 3: User Story 1 - Impact-Based Alert Labels (P1)

**Goal**: Generated rules carry priority and severity labels matching alert impact.

**Independent Test**: Inspect generated alert rules or module outputs and confirm label defaults per alert category.

- [x] T007 [US1] Apply P1/critical default only to `replicas_no` in `modules/dashboard/modules/alerts/block-service/locals.tf`
- [x] T008 [US1] Apply P2/warning defaults to degradation alerts in `modules/dashboard/modules/alerts/block-service/locals.tf`
- [x] T009 [US1] Apply P3/warning defaults to network anomaly alerts in `modules/dashboard/modules/alerts/block-service/locals.tf`
- [x] T010 [US1] Merge alert type labels into each generated rule in `modules/dashboard/modules/alerts/block-service/outputs.tf`

---

## Phase 4: User Story 2 - Avoid HPA Alerts Without HPA Context (P1)

**Goal**: HPA min/max rules are generated only when explicitly enabled or configured with manual thresholds.

**Independent Test**: Generate rules for default service config and confirm HPA min/max rules are absent.

- [x] T011 [US2] Add HPA min/max enablement locals in `modules/dashboard/modules/alerts/block-service/locals.tf`
- [x] T012 [US2] Gate min/max replica rules with enablement locals in `modules/dashboard/modules/alerts/block-service/outputs.tf`
- [x] T013 [US2] Update HPA alert input comments in `modules/dashboard/modules/alerts/block-service/variables.tf`

---

## Phase 5: User Story 3 - Reduce Default Network Alert Noise (P2)

**Goal**: Network anomaly alerts are opt-in by default.

**Independent Test**: Generate rules for default service config and confirm network in/out rules are absent.

- [x] T014 [US3] Add network opt-in locals in `modules/dashboard/modules/alerts/block-service/locals.tf`
- [x] T015 [US3] Gate network in/out rules with opt-in locals in `modules/dashboard/modules/alerts/block-service/outputs.tf`
- [x] T016 [US3] Update network alert input defaults and descriptions in `modules/dashboard/modules/alerts/block-service/variables.tf`

---

## Phase 6: User Story 4 - Alert on Deployment Unavailable Replicas (P2)

**Goal**: Deployment services get a reusable unavailable replicas alert with `> 0` for `30s`.

**Independent Test**: Generate rules for a deployment and confirm the unavailable replicas rule exists; generate rules for a non-deployment workload and confirm it is absent.

- [x] T017 [US4] Add deployment unavailable replicas expression default in `modules/dashboard/modules/alerts/block-service/locals.tf`
- [x] T018 [US4] Add `alerts.unavailable_replicas` input object in `modules/dashboard/modules/alerts/block-service/variables.tf`
- [x] T019 [US4] Add deployment-only unavailable replicas enablement local in `modules/dashboard/modules/alerts/block-service/locals.tf`
- [x] T020 [US4] Generate unavailable replicas alert rule in `modules/dashboard/modules/alerts/block-service/outputs.tf`
- [x] T021 [US4] Update enabled-alert example in `tests/dashboard-widget-alerts-enabled/1-example.tf`

---

## Phase 7: Documentation & Validation

- [x] T022 Regenerate block-service README in `modules/dashboard/modules/alerts/block-service/README.md`
- [x] T023 Run Terraform formatting checks for changed Terraform files
- [x] T024 Run Terraform validation for root, dashboard, and block-service alert module scopes
- [x] T025 Run `git diff --check`
- [x] T026 Update PR description with implemented alert cleanup behavior

---

## Dependencies & Execution Order

### Phase Dependencies

- Setup has no dependencies.
- Foundational changes must complete before user story changes.
- US1 label work should complete before validating alert priority behavior.
- US2 and US3 can proceed independently after foundational locals are in place.
- US4 depends on the output rule structure and label merge pattern from US1.
- Documentation and validation depend on implementation completion.

### User Story Dependencies

- **US1 (P1)**: No dependency after foundational setup.
- **US2 (P1)**: No dependency after foundational setup.
- **US3 (P2)**: No dependency after foundational setup.
- **US4 (P2)**: Depends on label defaults and output rule merge pattern.

### Parallel Opportunities

- `T003` can run in parallel with source review.
- `T011` and `T014` can be implemented independently after `T004`.
- `T013` and `T016` can be documented in parallel.
- Validation commands can be run by scope after initialization.

## Implementation Strategy

### MVP First

1. Remove forced P1 and introduce alert type label defaults.
2. Gate HPA alerts so services without HPA do not get HPA min/max rules.
3. Validate formatting and module output shape.

### Incremental Delivery

1. Add network opt-in gating.
2. Add deployment unavailable replicas default alert.
3. Update docs/examples.
4. Run full Terraform validation.

## Implementation Notes

- `replicas_no` and `unavailable_replicas` are related but not identical. `replicas_no` covers full no-running-replica outage; `unavailable_replicas` covers deployment rollout or capacity degradation where one or more replicas are unavailable.
- The broader DS-10938 scope is intentionally not copied into default module alerts.
- Terraform test fixture files created during development were removed by user request and are not restored here.
