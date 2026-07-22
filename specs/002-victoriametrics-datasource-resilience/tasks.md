# Tasks: VictoriaMetrics Datasource Resilience

**Input**: Design documents from `/specs/002-victoriametrics-datasource-resilience/`  
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, quickstart.md

**Tests**: Required by the request workflow and TDD.

**Organization**: Single independently testable user story.

## Phase 1: Setup

- [x] T001 Confirm Jira comment root cause and validated mitigation in DS-11630
- [x] T002 Confirm chart value shape for `vminsert.extraArgs` and `vmselect.extraArgs`
- [x] T003 Confirm chart value shape for Grafana MySQL `primary.podAnnotations` and `primary.pdb`

## Phase 2: User Story 1 - Default Resilient VictoriaMetrics Queries (Priority: P1)

**Goal**: Default module-generated VictoriaMetrics values include the validated datasource resilience arguments.

**Independent Test**: `terraform -chdir=modules/victoria-metrics test`

### Tests for User Story 1

- [x] T004 [US1] Add failing Terraform test for default VictoriaMetrics resilience values in `modules/victoria-metrics/tests/defaults.tftest.hcl`

### Implementation for User Story 1

- [x] T005 [US1] Add default `extraArgs` for `vminsert` and `vmselect` in `modules/victoria-metrics/main.tf`
- [x] T006 [US1] Run `terraform -chdir=modules/victoria-metrics test` and verify it passes

## Phase 3: User Story 2 - Protected Grafana MySQL Primary (Priority: P2)

**Goal**: Default module-generated Grafana MySQL values include the validated primary pod annotation and PDB policy.

**Independent Test**: `terraform -chdir=modules/grafana test`

### Tests for User Story 2

- [x] T007 [US2] Add failing Terraform test for default Grafana MySQL primary protection values in `modules/grafana/tests/mysql-defaults.tftest.hcl`

### Implementation for User Story 2

- [x] T008 [US2] Add default `primary.podAnnotations` and `primary.pdb` settings in `modules/grafana/main.tf`
- [x] T009 [US2] Run `terraform -chdir=modules/grafana test` and verify it passes

## Phase 4: Polish & Validation

- [x] T010 Run repository Terraform formatting for touched Terraform files
- [x] T011 Review `git diff` for scope and absence of client-specific Terraform names

## Dependencies & Execution Order

- T001 through T003 before story test work.
- T004 must fail before T005.
- T007 must fail before T008.
- T006 and T009 before polish validation.

## Implementation Strategy

Use the smallest default-only module changes that satisfy the validated mitigations. Preserve the existing `extra_configs` and `mysql_extra_configs` override mechanisms.
