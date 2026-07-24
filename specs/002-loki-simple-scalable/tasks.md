# Tasks: Loki SimpleScalable First-Class Support

**Input**: Design documents from `specs/002-loki-simple-scalable/`  
**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/`

**Tests**: Include URL contract and guardrail validations per acceptance criteria.

**Organization**: Tasks grouped by user story for independent delivery and testing.

## Phase 1: Setup

- [x] T001 Confirm feature branch `002-loki-simple-scalable` and artifact set under `specs/002-loki-simple-scalable/`
- [x] T002 Review current Loki URL wiring in `main.tf`, `locals.tf`, and `modules/loki-stack/main.tf`
- [x] T003 [P] Identify affected files: `modules/loki-stack/*`, root `variables.tf`, `README.md`, `tests/`

---

## Phase 2: Foundational

- [x] T004 Add mode-aware URL locals (`loki_query_url`, `loki_push_url`) in `modules/loki-stack/locals.tf`
- [x] T005 Add SimpleScalable component replica defaults (read=2, write=2, backend=1) in `modules/loki-stack/locals.tf`
- [x] T006 Add `deploymentMode` and SimpleScalable storage validation in `modules/loki-stack/variables.tf`
- [x] T007 Add matching root-level `loki_stack` validation in `variables.tf`
- [x] T008 Add schema/compactor object-store alignment for SimpleScalable in `modules/loki-stack/locals.tf`

---

## Phase 3: User Story 1 - Logs visible in Grafana after SimpleScalable deploy (P1)

**Goal**: Grafana datasource and Promtail use correct mode-aware endpoints.

**Independent Test**: Plan/apply SimpleScalable; query logs in Grafana without manual datasource URL edit.

- [x] T009 [US1] Export `query_url`, `push_url`, `deployment_mode` in `modules/loki-stack/outputs.tf`
- [x] T010 [US1] Wire effective read/write/backend configs in `modules/loki-stack/main.tf`
- [x] T011 [US1] Fix Promtail clients reference and default to `local.promtail_clients` in `modules/loki-stack/main.tf`
- [x] T012 [US1] Wire Grafana datasource to `module.loki[0].query_url` in `main.tf` and `locals.tf`

---

## Phase 4: User Story 2 - Safe SimpleScalable defaults and guardrails (P2)

**Goal**: Sensible defaults and fail-fast validation for incompatible configs.

**Independent Test**: Validate fails for SimpleScalable + filesystem; replica defaults apply when unset.

- [x] T013 [US2] Apply effective schema config and compactor options in `modules/loki-stack/main.tf`
- [x] T014 [US2] Verify user replica overrides preserved via merge in `modules/loki-stack/locals.tf`
- [x] T015 [US2] Confirm SingleBinary URLs unchanged in plan outputs for `tests/loki-simple-scalable/`

---

## Phase 5: User Story 3 - Documented migration and test coverage (P3)

**Goal**: README, submodule docs, and dedicated test example.

**Independent Test**: `tests/loki-simple-scalable/` plan outputs match URL contract.

- [x] T016 [US3] Add `tests/loki-simple-scalable/` with setup, example, and README
- [x] T017 [US3] Add deployment modes, URL matrix, and migration notes to root `README.md`
- [x] T018 [US3] Update `modules/loki-stack/README.md` with output and mode references
- [x] T019 [US3] Add `.terraformignore` for Terraform artifacts

---

## Phase 6: Final Validation

- [x] T020 Run `terraform validate` at repo root and record pass in `specs/002-loki-simple-scalable/quickstart.md`
- [x] T021 Run `terraform plan` in `tests/loki-simple-scalable/` and verify URL outputs against `contracts/loki-url-contract.md`
- [x] T022 Update task completion state in `specs/002-loki-simple-scalable/tasks.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- Setup (Phase 1) → Foundational (Phase 2) → User Stories (Phases 3–5) → Final Validation (Phase 6)

### User Story Dependencies

- **US1 (P1)**: Depends on Foundational locals/validation
- **US2 (P2)**: Depends on US1 module wiring
- **US3 (P3)**: Can proceed in parallel with US2 after US1 outputs exist

### Parallel Opportunities

- T003, T016, T017 can run in parallel after T002
- T009–T012 sequential within US1 (same module files)

---

## Implementation Strategy

### MVP First (User Story 1)

1. Complete Phases 1–2 and US1 (T001–T012)
2. Validate SC-001 before docs/tests polish

### Incremental Delivery

1. Add guardrails (US2) and verify validate failures
2. Add tests/docs (US3) and full acceptance validation

## Implementation Notes

- Code implemented on branch `002-loki-simple-scalable`; Speckit artifacts backfilled after initial implementation.
- Distributed mode: URL fallback only; full defaults deferred per spec out-of-scope.
- AWS wrapper and consumer repo bumps tracked as separate follow-up PRs.
