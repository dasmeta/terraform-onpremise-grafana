# Tasks: Preserve Existing Dashboard Queries

**Input**: Design documents from `specs/005-legacy-dashboard-compat/`

**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, and `contracts/dashboard-query-compatibility.md`

**Tests**: Native Terraform tests are required. Write the test tasks before the source tasks and confirm they fail before implementing the compatibility input.

**Organization**: Tasks are grouped by user story so each outcome can be verified independently.

## Phase 1: Setup

**Purpose**: Prepare the isolated native Terraform test fixture without changing module behaviour.

- [X] T001 Create the mocked Grafana Terraform-test fixture in `tests/dashboard-query-compatibility/0-setup.tf` with the repository’s Terraform and Grafana provider constraints.
- [X] T002 [P] Record the nine-widget modern and legacy expression fixture rows in `tests/dashboard-query-compatibility/1-query-contract.tftest.hcl` using dashboard-module outputs rather than a live Grafana resource.

---

## Phase 2: Foundational Contract

**Purpose**: Establish the single dashboard-scoped configuration path that every affected widget consumes.

**⚠️ CRITICAL**: Complete this phase before implementing any query branch.

- [X] T003 Define the documented `defaults.query_compatibility.legacy_dashboard_queries` public contract and false default in `variables.tf` and `modules/dashboard/variables.tf`.
- [X] T004 Resolve the Boolean once, defaulting safely to `false`, in `modules/dashboard/locals.tf` without changing data-source, alert, layout, or existing widget-default merging.
- [X] T005 Propagate the resolved selection only to affected calls in `modules/dashboard/widgets-container.tf`, `modules/dashboard/widgets-ingress.tf`, and `modules/dashboard/widgets-pod.tf`.

**Checkpoint**: The dashboard module can route the compatibility selection, but all affected widget query modules still require their inputs and conditional expressions.

---

## Phase 3: User Story 1 - Preserve a Production Dashboard (Priority: P1) 🎯 MVP

**Goal**: An opted-in existing dashboard renders the same legacy query contract that is currently deployed.

**Independent Test**: Run the compatibility-enabled case in `tests/dashboard-query-compatibility/1-query-contract.tftest.hcl` and verify every affected target matches the pre-`7b40f31` and pre-`aa9b768` expressions.

### Tests for User Story 1

- [X] T006 [US1] Add failing legacy-mode assertions for all nine affected widget outputs in `tests/dashboard-query-compatibility/1-query-contract.tftest.hcl`, including usage-memory metrics, pod-memory rate queries, and pre-rollout pod selectors.

### Implementation for User Story 1

- [X] T007 [P] [US1] Add the optional compatibility Boolean and legacy memory expressions to `modules/dashboard/modules/widgets/container/memory/variables.tf` and `modules/dashboard/modules/widgets/container/memory/base.tf`.
- [X] T008 [P] [US1] Add the optional compatibility Boolean and legacy memory expressions to `modules/dashboard/modules/widgets/ingress/memory/variables.tf` and `modules/dashboard/modules/widgets/ingress/memory/base.tf`.
- [X] T009 [P] [US1] Add the optional compatibility Boolean and combined legacy memory/selector expressions to `modules/dashboard/modules/widgets/pod/memory/variables.tf` and `modules/dashboard/modules/widgets/pod/memory/base.tf`.
- [X] T010 [P] [US1] Add the optional compatibility Boolean and pre-rollout selector expressions to `modules/dashboard/modules/widgets/container/network/variables.tf` and `modules/dashboard/modules/widgets/container/network/base.tf`.
- [X] T011 [P] [US1] Add the optional compatibility Boolean and pre-rollout selector expressions to `modules/dashboard/modules/widgets/container/network-traffic/variables.tf`, `modules/dashboard/modules/widgets/container/network-traffic/base.tf`, `modules/dashboard/modules/widgets/container/network-error/variables.tf`, and `modules/dashboard/modules/widgets/container/network-error/base.tf`.
- [X] T012 [P] [US1] Add the optional compatibility Boolean and pre-rollout selector expressions to `modules/dashboard/modules/widgets/container/replicas/variables.tf`, `modules/dashboard/modules/widgets/container/replicas/base.tf`, `modules/dashboard/modules/widgets/pod/cpu/variables.tf`, `modules/dashboard/modules/widgets/pod/cpu/base.tf`, `modules/dashboard/modules/widgets/pod/restarts/variables.tf`, and `modules/dashboard/modules/widgets/pod/restarts/base.tf`.
- [X] T013 [US1] Run the legacy-enabled test case in `tests/dashboard-query-compatibility/1-query-contract.tftest.hcl` and confirm all legacy-expression assertions pass.

**Checkpoint**: An explicitly opted-in dashboard preserves its historical container and pod query behaviour.

---

## Phase 4: User Story 2 - Keep Modern Defaults for New Dashboards (Priority: P2)

**Goal**: Dashboards that omit compatibility retain the current working-set-memory and rollout-aware selector behaviour.

**Independent Test**: Run the omitted/false configuration cases and compare all nine widget targets to the current module expressions.

### Tests for User Story 2

- [X] T014 [US2] Add failing omitted-setting and explicit-false assertions to `tests/dashboard-query-compatibility/1-query-contract.tftest.hcl` for working-set memory and primary/canary-aware selectors.

### Implementation for User Story 2

- [X] T015 [US2] Ensure the false/default branch in `modules/dashboard/locals.tf`, `modules/dashboard/modules/widgets/container/memory/base.tf`, `modules/dashboard/modules/widgets/ingress/memory/base.tf`, `modules/dashboard/modules/widgets/pod/memory/base.tf`, `modules/dashboard/modules/widgets/container/network/base.tf`, `modules/dashboard/modules/widgets/container/network-traffic/base.tf`, `modules/dashboard/modules/widgets/container/network-error/base.tf`, `modules/dashboard/modules/widgets/container/replicas/base.tf`, `modules/dashboard/modules/widgets/pod/cpu/base.tf`, and `modules/dashboard/modules/widgets/pod/restarts/base.tf` renders the pre-feature modern expressions exactly.
- [X] T016 [US2] Run the modern-default test cases in `tests/dashboard-query-compatibility/1-query-contract.tftest.hcl` and confirm all modern-expression assertions pass.

**Checkpoint**: Existing callers that do not use the new setting receive unchanged modern module output.

---

## Phase 5: User Story 3 - Apply Compatibility Predictably (Priority: P3)

**Goal**: Compatibility is isolated per dashboard, fully documented, and cannot affect alert rules or unrelated widget behaviour.

**Independent Test**: Generate two dashboard configurations with opposing selections, and a service alert fixture, then verify their query and alert outputs independently.

### Tests for User Story 3

- [ ] T017 [US3] Add per-dashboard isolation and alert-rule non-interference assertions to `tests/dashboard-query-compatibility/1-query-contract.tftest.hcl`; verify the compatibility flag changes only documented dashboard targets.

### Implementation for User Story 3

- [X] T018 [US3] Add the public YAML example, false-default behaviour, nine-widget scope, and alert exclusion to `README.md` and `modules/dashboard/README.md` without overwriting generated input documentation.
- [X] T019 [US3] Reconcile `specs/005-legacy-dashboard-compat/contracts/dashboard-query-compatibility.md` with the final expression set and run the full fixture at `tests/dashboard-query-compatibility/`.

**Checkpoint**: The feature is documented and bounded; alerts and unrelated dashboard content remain independently reviewable.

---

## Phase 6: Verification, Release, and Downstream Adoption

**Purpose**: Validate code quality, publish the compatibility feature, and prove the consumer dashboard will not change.

- [ ] T020 Run the commands in `specs/005-legacy-dashboard-compat/quickstart.md` (`terraform fmt -check -recursive`, changed-directory validation, and the focused Terraform test) and record results in the PR description.
- [X] T021 [P] Run the repository pre-commit/documentation workflow for `README.md`, `modules/dashboard/README.md`, and the modified Terraform files; retain only intentional generated documentation changes.
- [ ] T022 Create and review the on-premises module PR from the files listed in `specs/005-legacy-dashboard-compat/plan.md`, release the approved backward-compatible version, and record the immutable version in the release notes.
- [ ] T023 Update the released on-premises module source in `terraform-aws-grafanav12/main.tf`, confirm its `application_dashboard[].defaults` pass-through, test it, and publish the corresponding wrapper release.
- [ ] T024 Add `defaults.query_compatibility.legacy_dashboard_queries: true` only under the target dashboard in consumer Grafana YAML; do not hand-edit generated Terraform output.
- [ ] T025 Regenerate Terraform through the approved workflow, run a Terraform Cloud plan, and verify the target `grafana_dashboard.metrics` resource has no `config_json` update; review any alert diffs separately.
- [ ] T026 Apply only the reviewed consumer Grafana plan, then visually and query-functionally confirm the existing dashboard remains unchanged.

---

## Dependencies & Execution Order

- Phase 1 → Phase 2 → User Story 1 is the MVP path.
- User Story 2 depends on the same routing contract in Phase 2 but can be verified after User Story 1’s source work because it checks the opposite branch.
- User Story 3 depends on both query branches and completes the public documentation and isolation guarantee.
- Release and consumer adoption depend on all three user stories and local verification.

## Parallel Opportunities

- T007 through T012 are independent widget-module edits once T003 through T005 are complete; each touches distinct widget files.
- T020 and T021 can run in parallel after the focused tests pass.
- The on-premises release (T022) must precede wrapper work (T023), which must precede consumer adoption (T024–T026).

## Implementation Strategy

1. Build and run the failing P1 legacy contract test.
2. Implement the single defaults route and the nine focused widget branches.
3. Make P1 green, then prove the default branch remains modern for P2.
4. Complete P3 isolation, alert-safety, and documentation.
5. Release through the on-premises module → AWS wrapper → consumer YAML chain, using the Terraform Cloud dashboard plan as the final gate.
