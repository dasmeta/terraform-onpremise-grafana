# Tasks: MSK CloudWatch Monitoring

**Input**: Design documents from `specs/004-msk-monitoring/`  
**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/`

**Tests**: Include dashboard module test example and `terraform validate` per spec acceptance criteria.

**Organization**: Tasks grouped by user story for independent delivery and testing.

## Phase 1: Setup

**Purpose**: Confirm feature context and baseline patterns before implementation

- [x] T001 Confirm feature branch `004-msk-monitoring` and artifact set under `specs/004-msk-monitoring/`
- [x] T002 Review CloudWatch block patterns in `modules/dashboard/modules/blocks/rds/` and `modules/dashboard/modules/blocks/elasticache_redis/`
- [x] T003 [P] Review MSK contract in `specs/004-msk-monitoring/contracts/msk-dashboard-block-contract.md` and widget reference in `modules/dashboard/modules/widgets/rds/cpu/base.tf`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Shared conventions required before MSK widgets and block work

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T004 Confirm CloudWatch widget defaults (`datasource_uid`, `period`, `region`) in `modules/dashboard/locals.tf` apply to new MSK widgets without changes
- [x] T005 [P] Confirm block type registration pattern in `modules/dashboard/locals.tf` (`blocks_by_type`, `blocks_results`) supports adding `msk` key

**Checkpoint**: Foundation ready — MSK widget implementation can begin

---

## Phase 3: User Story 1 - MSK Dashboard Monitoring (Priority: P1) 🎯 MVP

**Goal**: Operators can add `block/msk` and see MSK health, throughput, partition, and lag panels in Grafana.

**Independent Test**: Configure `block/msk` with a cluster name; dashboard plan renders MSK CloudWatch panels for CPU, memory, throughput, partitions, offline partitions, and optional lag.

### Implementation for User Story 1

- [x] T006 [P] [US1] Create `msk/cpu` widget (base.tf, variables.tf, locals.tf, output.tf, README.md) in `modules/dashboard/modules/widgets/msk/cpu/`
- [x] T007 [P] [US1] Create `msk/memory` widget in `modules/dashboard/modules/widgets/msk/memory/`
- [x] T008 [P] [US1] Create `msk/throughput_in` widget in `modules/dashboard/modules/widgets/msk/throughput_in/`
- [x] T009 [P] [US1] Create `msk/throughput_out` widget in `modules/dashboard/modules/widgets/msk/throughput_out/`
- [x] T010 [P] [US1] Create `msk/partitions` widget in `modules/dashboard/modules/widgets/msk/partitions/`
- [x] T011 [P] [US1] Create `msk/offline_partitions` widget in `modules/dashboard/modules/widgets/msk/offline_partitions/`
- [x] T012 [P] [US1] Create `msk/consumer_lag` widget with optional `consumer_groups` input in `modules/dashboard/modules/widgets/msk/consumer_lag/`
- [x] T013 [US1] Create `block/msk` block (variables.tf, output.tf, README.md) in `modules/dashboard/modules/blocks/msk/` per contract layout
- [x] T014 [US1] Add MSK widget module wiring in `modules/dashboard/widgets-msk.tf`
- [x] T015 [US1] Register `module "block_msk"` in `modules/dashboard/widgets_blocks.tf`
- [x] T016 [US1] Add `msk` to `blocks_results` and widget panel merge entries in `modules/dashboard/locals.tf`

**Checkpoint**: User Story 1 complete — `block/msk` renders all MSK dashboard panels

---

## Phase 4: User Story 2 - Optional MSK Alerting (Priority: P2)

**Goal**: Operators can enable MSK alerts for offline partitions with route-friendly labels.

**Independent Test**: Enable `alerts.enabled = true` on a `block/msk` row; plan includes offline partition alert rules using CloudWatch datasource.

### Implementation for User Story 2

- [x] T017 [US2] Extend CloudWatch query model support for `datasource_type = "cloudwatch"` in `modules/alerts/modules/rules/main.tf` and `modules/alerts/modules/rules/variables.tf`
- [x] T018 [US2] Create MSK alert rule generator in `modules/dashboard/modules/alerts/block-msk/` (variables.tf, main.tf or locals.tf, outputs.tf, README.md)
- [x] T019 [US2] Wire `block_msk_alerts` into `modules/dashboard/alerts.tf` and append rules to `local.widget_alert_rules`

**Checkpoint**: User Story 2 complete — offline partition alerts generated when enabled

---

## Phase 5: User Story 3 - Consumer Documentation And Examples (Priority: P3)

**Goal**: Consumers can adopt MSK monitoring via documented examples with generic cluster names.

**Independent Test**: Follow test example README; `terraform validate` passes in `modules/dashboard/tests/msk-cloudwatch/`.

### Implementation for User Story 3

- [x] T020 [P] [US3] Add `modules/dashboard/tests/msk-cloudwatch/0-setup.tf` and `1-example.tf` with generic `cluster_names = ["example-msk-cluster"]`
- [x] T021 [US3] Add `modules/dashboard/tests/msk-cloudwatch/README.md` describing expected plan output
- [x] T022 [US3] Document `block/msk` inputs and example HCL in `modules/dashboard/README.md` and root `README.md`

**Checkpoint**: User Story 3 complete — docs and test example ready for consumers

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Validation and acceptance evidence

- [x] T023 Run `terraform validate` at repository root
- [x] T024 Run `terraform validate` in `modules/dashboard/tests/msk-cloudwatch/`
- [x] T025 [P] Regenerate terraform-docs output if module README inputs changed (`modules/dashboard/modules/blocks/msk/README.md`, widget READMEs)
- [x] T026 Update acceptance checklist in `specs/004-msk-monitoring/quickstart.md` with validation results

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)** → **Foundational (Phase 2)** → **User Stories (Phases 3–5)** → **Polish (Phase 6)**
- **User Story 1 (P1)** is the MVP; stop after Phase 3 for dashboard-only delivery
- **User Story 2 (P2)** depends on US1 block inputs (`cluster_names`, `region`, `datasource_uid`)
- **User Story 3 (P3)** can start after US1 block exists (test example references `block/msk`)

### User Story Dependencies

- **US1 (P1)**: Depends on Foundational phase only
- **US2 (P2)**: Depends on US1 `block/msk` entity; independently testable via alert plan output
- **US3 (P3)**: Depends on US1; independently testable via validate/plan in test folder

### Within User Story 1

- T006–T012 (widgets) can run in parallel
- T013 depends on widget type names being finalized
- T014–T016 depend on T013 block output layout

### Parallel Opportunities

```bash
# Parallel widget creation (US1):
T006, T007, T008, T009, T010, T011, T012

# Parallel after US1:
T020 (test scaffold) can start once T013 block contract is stable
T025 (terraform-docs) can run in parallel with T023/T024 at end
```

---

## Parallel Example: User Story 1

```bash
# Launch all MSK widgets together:
Task: "Create msk/cpu widget in modules/dashboard/modules/widgets/msk/cpu/"
Task: "Create msk/memory widget in modules/dashboard/modules/widgets/msk/memory/"
Task: "Create msk/throughput_in widget in modules/dashboard/modules/widgets/msk/throughput_in/"
Task: "Create msk/throughput_out widget in modules/dashboard/modules/widgets/msk/throughput_out/"
Task: "Create msk/partitions widget in modules/dashboard/modules/widgets/msk/partitions/"
Task: "Create msk/offline_partitions widget in modules/dashboard/modules/widgets/msk/offline_partitions/"
Task: "Create msk/consumer_lag widget in modules/dashboard/modules/widgets/msk/consumer_lag/"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001–T003)
2. Complete Phase 2: Foundational (T004–T005)
3. Complete Phase 3: User Story 1 (T006–T016)
4. **STOP and VALIDATE**: Run `terraform validate` at repo root
5. Demo dashboard block in plan output before alerts/docs

### Incremental Delivery

1. US1 → MSK dashboards (MVP for DMVP-10260 visibility)
2. US2 → Offline partition alerts when ticket requires alerting
3. US3 → Tests and README for consumer adoption
4. Phase 6 → Full acceptance validation

### Suggested MVP Scope

- **Minimum**: T001–T016 + T023 (dashboard block only)
- **Full feature**: T001–T026 (includes alerts, tests, docs)

---

## Notes

- Do not modify `block/rds` or any RDS widgets — MSK only per spec out-of-scope
- Use generic cluster names in all examples (`example-msk-cluster`)
- CloudWatch datasource provisioning remains consumer responsibility
- Mark tasks `[X]` in this file as each completes during `/speckit.implement`
