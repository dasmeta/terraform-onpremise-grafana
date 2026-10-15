# Tasks: Legacy Service-Block Query Compatibility

**Input**: `specs/006-legacy-service-block-query-compat/spec.md` and `plan.md`
**Prerequisites**: Approved specification and implementation plan

## Phase 1: Contract tests

- [x] T001 Create `modules/dashboard/tests/2-service-block-query-contract.tftest.hcl` with a compatibility-on `block/service` dashboard case that asserts the deployed service status-panel, phase-alert, and memory-alert expressions.
- [x] T002 Run the focused test and record the expected RED failure caused by the absent `legacy_service_block_queries` interface.
- [x] T003 Add a no-setting case to the same test that asserts v1.31.0 modern selector and working-set-memory behavior.

## Phase 2: Dashboard service-panel implementation

- [x] T004 Add the safe, false-by-default dashboard local in `modules/dashboard/locals.tf`.
- [x] T005 Pass the local to `modules/dashboard/modules/blocks/service` from `modules/dashboard/widgets_blocks.tf`.
- [x] T006 Add the service-block input and attach it only to generated `container/replicas` widget configuration in `modules/dashboard/modules/blocks/service/{variables.tf,locals.tf}`.
- [x] T007 Add the replicas-widget input and exact deployed selector branch in `modules/dashboard/modules/widgets/container/replicas/{variables.tf,base.tf}`.
- [x] T008 Pass the per-widget marker only to the replicas widget in `modules/dashboard/widgets-container.tf`.
- [x] T009 Run the focused native test; confirm dashboard compatibility assertions become green.

## Phase 3: Service-alert implementation

- [x] T010 Pass the dashboard local into only `module "block_service_alerts"` in `modules/dashboard/alerts.tf`.
- [x] T011 Add the alert-submodule input and derived phase-selector/memory-metric locals in `modules/dashboard/modules/alerts/block-service/{variables.tf,locals.tf}`.
- [x] T012 Substitute only those two locals in `modules/dashboard/modules/alerts/block-service/outputs.tf`.
- [x] T013 Run the focused native test; confirm all dashboard and alert contract assertions are green.

## Phase 4: Documentation and verification

- [x] T014 Update compatibility descriptions in `modules/dashboard/variables.tf` and root `variables.tf`.
- [x] T015 Regenerate `README.md` with `pre-commit run terraform_docs --all-files`.
- [x] T016 Run `terraform fmt -check -recursive`, `terraform -chdir=modules/dashboard init -backend=false`, `terraform -chdir=modules/dashboard validate`, `terraform -chdir=modules/dashboard test`, and `pre-commit run --all-files`.
- [x] T017 Compare final expressions to the recorded Terraform Cloud plan and commit only the feature package, source, tests, and generated docs.
