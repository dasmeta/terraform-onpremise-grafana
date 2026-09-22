# Tasks: Canonical MSP Uptime and Latency

**Input**: Design documents from `specs/004-canonical-sli-queries/`
**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/query-contract.md`

## Phase 1: Contract Tests

- [x] T001 [P] [US1] Add failing availability widget expression/unit/period tests in `modules/dashboard/modules/widgets/sla-slo-sli/nginx_availability/tests/query_contract.tftest.hcl`
- [x] T002 [P] [US1] Add failing weighted latency expression/unit/period tests in `modules/dashboard/modules/widgets/sla-slo-sli/nginx_latency/tests/query_contract.tftest.hcl`
- [x] T003 [P] [US2] Add failing availability/latency alert and annotation tests in `modules/dashboard/modules/alerts/block-sla-nginx/tests/query_contract.tftest.hcl`
- [x] T004 [US1] Run the new tests and capture the expected red state before source changes

## Phase 2: User Story 1 - Trust the SLA/SLO dashboard (Priority: P1)

**Independent Test**: Both widget test suites render the exact contract for empty and non-empty scopes.

- [x] T005 [P] [US1] Normalize optional filters in `modules/dashboard/modules/widgets/sla-slo-sli/nginx_availability/locals.tf`
- [x] T006 [P] [US1] Normalize optional filters in `modules/dashboard/modules/widgets/sla-slo-sli/nginx_latency/locals.tf`
- [x] T007 [US1] Correct availability period and expression in `modules/dashboard/modules/widgets/sla-slo-sli/nginx_availability/base.tf` and `variables.tf`
- [x] T008 [US1] Correct weighted latency, unit, thresholds, and period in `modules/dashboard/modules/widgets/sla-slo-sli/nginx_latency/base.tf` and `variables.tf`
- [x] T009 [US1] Make the dashboard wrapper resolve blank merged periods to `1d` in `modules/dashboard/widgets-sla-slo-sli.tf`
- [x] T010 [US1] Run both widget tests to green

## Phase 3: User Story 2 - Receive alerts with the same semantics (Priority: P2)

**Independent Test**: Alert output tests prove exact query and annotation semantics for default and filtered scopes.

- [x] T011 [US2] Normalize alert scope/interval settings in `modules/dashboard/modules/alerts/block-sla-nginx/locals.tf`
- [x] T012 [US2] Correct alert expressions and annotations in `modules/dashboard/modules/alerts/block-sla-nginx/outputs.tf`
- [x] T013 [US2] Run alert tests to green

## Phase 4: Polish and Verification

- [x] T014 Run `terraform fmt -recursive` and `terraform fmt -check -recursive`
- [x] T015 Run all touched module tests and validation available without external deployment
- [x] T016 Review the final diff for no new metrics, no customer identifiers, and preserved public inputs

## Dependencies and Execution Order

- T001-T003 are independent test authoring tasks; T004 gates production edits.
- T005-T009 depend on the red tests; T010 gates alert work.
- T011-T013 depend on the canonical dashboard contract.
- T014-T016 run after all implementation tasks.
