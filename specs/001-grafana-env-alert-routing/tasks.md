# Tasks: Multi-Environment Grafana Alert Routing

**Input**: Design documents from `specs/001-grafana-env-alert-routing/`  
**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/`

**Tests**: Include routing behavior validations because acceptance criteria require delivery/isolation proof.

**Organization**: Tasks are grouped by user story for independent delivery and testing.

## Phase 1: Setup

- [x] T001 Confirm feature branch `001-grafana-env-alert-routing` and artifact set under `specs/001-grafana-env-alert-routing/`
- [x] T002 Review current routing and alert-related inputs in `variables.tf`, `locals.tf`, and `main.tf`
- [x] T003 [P] Identify affected module files under `modules/`, `dashboards/`, and `tests/` for routing behavior updates

---

## Phase 2: Foundational

- [x] T004 Define canonical environment routing identity inputs in `variables.tf`
- [x] T005 Define topology mode inputs (`same_cluster_multi_namespace`, `multi_cluster_central_grafana`) in `variables.tf`
- [x] T006 Implement identity resolution precedence and defaults in `locals.tf`
- [x] T007 Implement validation rules for environment-to-channel mappings in `variables.tf`
- [x] T008 Add explicit unresolved-identity fallback contract (`ops-fallback` + misconfigured marking) in `variables.tf` and `README.md`

---

## Phase 3: User Story 1 - Route alerts by environment label (P1)

**Goal**: Ensure alerts are routed only to each environment's configured channels.

**Independent Test**: Trigger alerts for 3 environments and verify strict channel isolation.

- [x] T009 [US1] Implement environment label-based routing policy generation in `main.tf`
- [x] T010 [US1] Wire environment-to-channel mapping into alert/contact-point logic in `main.tf`
- [x] T011 [US1] Implement unresolved-identity routing path to `ops-fallback` in `main.tf`
- [x] T012 [US1] Add/adjust routing isolation tests for 3+ environments in `tests/`
- [x] T013 [US1] Add fallback behavior test coverage for unresolved identity in `tests/`
- [x] T014 [US1] Add README configuration examples for environment labels and channel mappings in `README.md`

---

## Phase 4: User Story 2 - Same-cluster multi-namespace mode (P2)

**Goal**: Keep namespace-based consolidated behavior while enabling per-environment routing.

**Independent Test**: Two namespaces mapped to two environments route alerts to separate channels.

- [x] T015 [US2] Implement namespace-derived environment identity defaults in `locals.tf` and `main.tf`
- [x] T016 [US2] Preserve namespace-variable dashboard compatibility in `main.tf` and `dashboards/`
- [x] T017 [US2] Add same-cluster multi-namespace example configuration in `README.md`
- [x] T018 [US2] Add/adjust same-cluster namespace mode routing tests in `tests/`

---

## Phase 6: Mirror to AWS v12 module

- [x] T022 Apply equivalent routing inputs and validation in `../terraform-aws-grafanav12/variables.tf`
- [x] T023 Apply equivalent identity resolution and routing logic in `../terraform-aws-grafanav12/locals.tf` and `../terraform-aws-grafanav12/main.tf`
- [x] T024 Add aligned topology examples and fallback behavior docs in `../terraform-aws-grafanav12/README.md`
- [x] T025 Add/adjust AWS v12 routing tests in `../terraform-aws-grafanav12/tests/`

---

## Phase 7: Final Validation

- [x] T026 Execute acceptance validation for 3+ environments in same-cluster mode and record evidence in `specs/001-grafana-env-alert-routing/quickstart.md`
- [ ] T027 Execute acceptance validation for 3+ environments in multi-cluster mode and record evidence in `specs/001-grafana-env-alert-routing/quickstart.md` (moved to separate follow-up ticket)
- [x] T028 Verify negative routing check (env A does not reach env B channel) and record evidence in `specs/001-grafana-env-alert-routing/quickstart.md`
- [x] T029 Verify unresolved identity routes to `ops-fallback` and mark behavior evidence in `specs/001-grafana-env-alert-routing/quickstart.md`
- [x] T030 [P] Run impacted repo checks/tests in `terraform-onpremise-grafana` and `terraform-aws-grafanav12`
- [x] T031 Update task completion state and implementation notes in `specs/001-grafana-env-alert-routing/tasks.md`

---
## Dependencies & Execution Order

### Phase Dependencies
- Setup (Phase 1) has no dependencies.
- Foundational (Phase 2) depends on Setup and blocks all user stories.
- User Story phases (Phase 3-5) depend on Foundational completion.
- Mirror phase (Phase 6) depends on stable on-prem implementation from Phase 3-5.
- Final validation (Phase 7) depends on completion of implementation and mirror phases.

### User Story Dependencies
- **US1 (P1)**: Starts after Foundational; delivers MVP routing capability.
- **US2 (P2)**: Starts after Foundational; should remain independently testable.

### Parallel Opportunities
- `T003` can run in parallel with documentation prep after `T002`.
- `T012` and `T013` can run in parallel after `T011` implementation.
- `T024` and `T025` can run in parallel in mirror phase after logic parity is established.
- `T030` can run in parallelized execution of repo-specific test commands.

---

## Parallel Example: User Story 1

```bash
# After T011 is implemented:
Task: "Add/adjust routing isolation tests for 3+ environments in tests/"
Task: "Add fallback behavior test coverage for unresolved identity in tests/"
```

---

## Implementation Strategy

### MVP First (User Story 1)
1. Complete Phase 1 and Phase 2.
2. Complete Phase 3 (US1).
3. Validate SC-001/SC-002/SC-005 before broader topology work.

### Incremental Delivery
1. Add same-cluster mode updates (US2) and verify independently.
2. Mirror behavior into AWS v12 and perform full acceptance validation.

## Implementation Notes

- Matcher-only routing approach from clarification is implemented using existing `alerts.notifications.policies[*].matchers`; no dedicated `environment_routing` wrapper is used.
- Same-cluster scenario is validated by dedicated example test folder:
  - `tests/multi-environment-alert-routing`
- Multi-cluster central Grafana topology is out of scope for this ticket and tracked in a separate follow-up ticket.
- AWS v12 mirror keeps pass-through behavior via `alerts = var.alerts` and matcher-based examples/tests.
