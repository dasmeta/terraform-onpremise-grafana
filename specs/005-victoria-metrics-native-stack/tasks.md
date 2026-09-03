# Tasks: VictoriaMetrics Native Stack

**Input**: Design documents from
`/specs/005-victoria-metrics-native-stack/`
**Prerequisites**: [plan.md](plan.md), [spec.md](spec.md),
[research.md](research.md), [data-model.md](data-model.md),
[contracts/metrics-stack-contract.md](contracts/metrics-stack-contract.md)

**Tests**: Native Terraform contract tests are mandatory. For each story, add
or change tests first, run the focused case, and confirm it fails for the
expected missing behavior before implementation.

**Organization**: Tasks are grouped by user story and use exact repository
paths. No task stages, commits, pushes, or otherwise mutates Git state.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel because it affects different files and has no
  incomplete dependency.
- **[Story]**: Maps the task to a user story in [spec.md](spec.md).

## Phase 1: Setup

**Purpose**: Prepare the existing focused fixture without changing production
behavior.

- [x] T001 Extend test fixture inputs and non-sensitive outputs for planned collector, node-exporter, native-node, and integration assertions in `tests/metrics-collector-selection/0-setup.tf` and `tests/metrics-collector-selection/1-example.tf`
- [x] T002 Record the feature's focused test commands and no-secret/no-Git constraints in `tests/metrics-collector-selection/README.md`

---

## Phase 2: Foundational Contracts

**Purpose**: Establish public types and stable selector-derived identities used
by every story. These tasks do not activate new resources by themselves.

- [x] T003 Add the typed independent `node_exporter` object, native VMAgent scrape flags/metric allowlist, and nullable Tempo remote-write contract in `variables.tf`
- [x] T004 Add stable exporter namespaces/fullnames, selected Prometheus write URL, converter state, and component monitor gates in `locals.tf`
- [x] T005 Extend child input contracts for converter state, native node discovery, generic native service scrape objects, and protected component values in `modules/victoria-metrics/variables.tf`, `modules/tempo/variables.tf`, and `modules/loki-stack/variables.tf`

**Checkpoint**: Public values can be resolved for every mode without yet
changing lifecycle.

---

## Phase 3: User Story 1 - Run VictoriaMetrics Without Prometheus (Priority: P1) 🎯 MVP

**Goal**: Make VM-only valid on a clean cluster with one VMAgent, official VM
CRDs, and native Kubernetes node discovery.

**Independent Test**: Plan `metrics_collector = "victoria_metrics"`,
`victoria_metrics.enabled = true`, `prometheus.enabled = false`; assert success,
converter disabled, ordered VM resource release, native node scrapes, and zero
generated `monitoring.coreos.com` objects.

### Tests for User Story 1

- [x] T006 [US1] Replace the current VM-only expected failure with successful standalone-mode and selected-backend assertions in `tests/metrics-collector-selection/2-root-contract.tftest.hcl`, then run the case and confirm it fails on the old Prometheus gate
- [x] T007 [P] [US1] Add failing Operator/CRD/resource-release ordering and VM-only converter override tests in `tests/metrics-collector-selection/3-operator-values.tftest.hcl`
- [x] T008 [P] [US1] Add failing VMAgent, kubelet, cAdvisor, optional resource endpoint, service-account auth-file, selector-protection, and no-Prometheus-API assertions in `tests/metrics-collector-selection/5-native-stack.tftest.hcl`

### Implementation for User Story 1

- [x] T009 [US1] Relax the root selected-backend precondition so VM selection requires only `victoria_metrics.enabled`, while preserving all invalid selector/backend failures in `outputs.tf`
- [x] T010 [US1] Add the module-local VM resource chart with deterministic multi-document rendering in `modules/victoria-metrics/charts/resources/Chart.yaml`, `modules/victoria-metrics/charts/resources/values.yaml`, and `modules/victoria-metrics/charts/resources/templates/resources.yaml`
- [x] T011 [US1] Split VM CR instances from the Operator release into a dependent `helm_release`, keep official CRD install/upgrade enabled, and protect VM-only cluster component monitors in `modules/victoria-metrics/main.tf` and `modules/victoria-metrics/locals.tf`
- [x] T012 [US1] Implement conditional converter values and filter raw environment/configuration bypasses in `modules/victoria-metrics/locals.tf`
- [x] T013 [US1] Generate selector-owned VMAgent and native kubelet/cAdvisor/resource `VMNodeScrape` objects with token/CA file paths and metric filtering in `modules/victoria-metrics/locals.tf`
- [x] T014 [US1] Pass standalone/converter/native-node inputs from root orchestration in `main.tf` and expose resource-release/native-node state in `modules/victoria-metrics/outputs.tf` and root `outputs.tf`
- [x] T015 [US1] Run the US1 focused tests and verify VM-only contains no Prometheus Operator API versions and preserves the existing VictoriaMetrics storage identity

**Checkpoint**: VictoriaMetrics-only is independently plan-valid and has a
clean-cluster CRD ordering boundary.

---

## Phase 4: User Story 2 - Keep Shared Exporters Across Collector Changes (Priority: P2)

**Goal**: Install kube-state-metrics and node-exporter independently and give
each exactly one discovery path selected by the active collector.

**Independent Test**: Compare Prometheus-only and VM-only plans; both retain
enabled exporter releases while monitor kinds switch mutually exclusively.

### Tests for User Story 2

- [x] T016 [P] [US2] Add failing independent node-exporter Helm value tests for pinned version, stable identity, resources, disabled annotation scrape, Prometheus monitor selection, metric filtering, and raw-override protection in `tests/metrics-collector-selection/5-native-stack.tftest.hcl`
- [x] T017 [P] [US2] Add failing root mode tests for exporter lifecycle, mutually exclusive discovery, disabled-exporter suppression, and status outputs in `tests/metrics-collector-selection/2-root-contract.tftest.hcl`
- [x] T018 [P] [US2] Extend Prometheus child tests to require both bundled exporters disabled after raw overrides in `tests/metrics-collector-selection/3-operator-values.tftest.hcl`

### Implementation for User Story 2

- [x] T019 [P] [US2] Create the independent node-exporter child module in `modules/node-exporter/main.tf`, `modules/node-exporter/locals.tf`, `modules/node-exporter/variables.tf`, `modules/node-exporter/outputs.tf`, and `modules/node-exporter/versions.tf`
- [x] T020 [P] [US2] Document the child input/output and lifecycle contract in `modules/node-exporter/README.md`
- [x] T021 [US2] Instantiate node-exporter with transition ordering and selected monitor gates in root `main.tf`, `locals.tf`, and `outputs.tf`
- [x] T022 [US2] Force bundled kube-state-metrics and node-exporter off after all raw Prometheus values in `modules/prometheus/values/prometheus-values.yaml.tpl`, `modules/prometheus/locals.tf`, and `modules/prometheus/main.tf`
- [x] T023 [US2] Generate the native node-exporter `VMServiceScrape`, retain the existing native KSM scrape, and suppress both native objects when their exporters or VMAgent are disabled in `modules/victoria-metrics/locals.tf`
- [x] T024 [US2] Run US2 tests and confirm every enabled shared exporter has exactly one selected discovery path in both single-backend modes

**Checkpoint**: Removing kube-prometheus-stack no longer removes either shared
exporter.

---

## Phase 5: User Story 3 - Migrate With Both Backends Installed (Priority: P3)

**Goal**: Preserve dual-backend migration while enforcing one active scraper,
conditional converter compatibility, one default datasource, and stable VM
storage.

**Independent Test**: Plan both dual-backend selector values and assert one
scraper, correct converter/default datasource, no duplicate module monitor, and
unchanged VM storage configuration.

### Tests for User Story 3

- [x] T025 [P] [US3] Add failing four-mode matrix assertions for scraper exclusivity, converter state, and default datasource in `tests/metrics-collector-selection/2-root-contract.tftest.hcl`
- [x] T026 [P] [US3] Add failing dual-mode converter and generated-object ownership assertions in `tests/metrics-collector-selection/3-operator-values.tftest.hcl` and `tests/metrics-collector-selection/4-generated-objects.tftest.hcl`
- [x] T027 [P] [US3] Add failing selector-only VM storage identity/retention/PVC equivalence assertions in `tests/metrics-collector-selection/5-native-stack.tftest.hcl`

### Implementation for User Story 3

- [x] T028 [US3] Complete root converter and scraper gates for both dual selector values and retain Prometheus-to-VM validation remote write only in Prometheus-selected mode in `locals.tf` and `main.tf`
- [x] T029 [US3] Make Grafana metrics datasource provisioning installation-aware with exactly one selected default and propagate the selected metrics UID to traces-to-metrics integration in `main.tf`, `modules/grafana/locals.tf`, and `modules/grafana/variables.tf`
- [x] T030 [US3] Complete non-sensitive dual-mode status outputs and child release identity outputs in `outputs.tf` and `modules/victoria-metrics/outputs.tf`
- [x] T031 [US3] Run US3 mode-matrix tests and compare VM cluster/PVC values across selector-only plans

**Checkpoint**: Both backends can coexist safely with exactly one collector and
a reversible selector handoff.

---

## Phase 6: User Story 4 - Preserve Module-Owned Metrics Integrations (Priority: P4)

**Goal**: Keep module-owned Grafana, Tempo, and Loki metrics integrations valid
without creating Prometheus custom resources in VM-only mode.

**Independent Test**: Plan VM-only with Grafana, Tempo, and Loki enabled; assert
VictoriaMetrics datasource/write targets, native component scrapes, protected
monitor suppression, and preservation of explicit Tempo URL.

### Tests for User Story 4

- [x] T032 [P] [US4] Add failing Tempo tests for selector-derived omitted remote write, explicit URL preservation, and raw monitor override protection in `tests/metrics-collector-selection/5-native-stack.tftest.hcl`
- [x] T033 [P] [US4] Add failing Loki/Grafana tests for VM-only Prometheus monitor/rule suppression and native Loki/Tempo service scrapes in `tests/metrics-collector-selection/5-native-stack.tftest.hcl`

### Implementation for User Story 4

- [x] T034 [US4] Resolve the selected write endpoint at root and pass protected monitor/remote-write values to Tempo in `locals.tf`, `main.tf`, `modules/tempo/locals.tf`, `modules/tempo/main.tf`, and `modules/tempo/values/tempo-values.yaml.tpl`
- [x] T035 [US4] Protect Loki ServiceMonitor/PrometheusRule behavior after raw values and expose stable service identity in `modules/loki-stack/locals.tf`, `modules/loki-stack/main.tf`, `modules/loki-stack/variables.tf`, and `modules/loki-stack/outputs.tf`
- [x] T036 [US4] Suppress Grafana's Prometheus ServiceMonitor in VM-only mode after raw values in `modules/grafana/main.tf` and `modules/grafana/locals.tf`
- [x] T037 [US4] Generate native Tempo and Loki `VMServiceScrape` objects from stable chart labels/ports and pass them to the VM resources release in root `locals.tf`, `main.tf`, and `modules/victoria-metrics/locals.tf`
- [x] T038 [US4] Run US4 tests and inspect VM-only generated objects for zero `monitoring.coreos.com` API versions

**Checkpoint**: Enabled module-owned integrations resolve only to installed,
selected backend resources.

---

## Phase 7: Polish and Cross-Cutting Verification

**Purpose**: Finish documentation, compatibility evidence, and complete module
verification.

- [x] T039 [P] Update root migration/VM-only usage and all new input/output descriptions in `README.md`, `modules/prometheus/README.md`, `modules/victoria-metrics/README.md`, `modules/tempo/README.md`, and `modules/loki-stack/README.md`
- [x] T040 [P] Add examples for Prometheus-only, dual migration, VM-only, application migration gate, rollback, and manual CRD cleanup in `README.md`
- [x] T041 Run scoped `terraform fmt -check`, root/fixture `terraform validate`, and `terraform test` from `tests/metrics-collector-selection`; fix only feature-related failures
- [x] T042 Run existing child-module tests that are available locally for Prometheus, Grafana, Tempo, Loki, kube-state-metrics, and VictoriaMetrics; record any unrelated baseline failures in the handoff
- [x] T043 Render pinned Helm paths for Prometheus-only and VM-only, verify CRD-before-resource ordering, one exporter instance, one scrape path, and absence of Prometheus custom resources in VM-only mode
- [x] T044 Run `git diff --check`, inspect all feature diffs for accidental secret values or unrelated edits, and provide the user a no-Git-mutation handoff

---

## Dependencies and Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Starts immediately.
- **Foundational contracts (Phase 2)**: Depends on setup; blocks all stories.
- **US1 (Phase 3)**: First implementation milestone; establishes VM-only and
  CRD/resource ordering.
- **US2 (Phase 4)**: Depends on US1's native VM resource path.
- **US3 (Phase 5)**: Depends on US1 and US2 mode/exporter gates.
- **US4 (Phase 6)**: Depends on US1's generic native service scrape path and
  US3's datasource selector.
- **Polish (Phase 7)**: Depends on all selected stories.

### Within Each User Story

1. Write or change the listed tests.
2. Run the narrow test and verify a meaningful failure.
3. Implement the smallest behavior needed.
4. Re-run the narrow test until it passes.
5. Re-run all earlier story tests before advancing.

### Parallel Opportunities

- T007 and T008 can be authored in parallel.
- T016, T017, and T018 affect separate test contracts.
- T019 and T020 can be prepared while Prometheus child tests are authored.
- T025, T026, and T027 can be authored independently.
- T032 and T033 cover separate component contracts.
- Documentation tasks T039 and T040 can run in parallel after behavior is
  stable.

## Implementation Strategy

### MVP First

1. Complete setup and foundational types.
2. Complete US1 and prove VM-only plan validity plus clean-cluster ordering.
3. Stop and validate the MVP before changing exporter lifecycle.

### Incremental Delivery

1. VM-only native collector foundation.
2. Independent exporters and complete metric coverage.
3. Reversible dual-backend migration contract.
4. Module-owned component integrations.
5. Full formatting, validation, render, and documentation pass.

## Notes

- Existing dirty-worktree changes belong to the user and must be preserved.
- No Git staging, commit, branch, reset, push, or PR action is permitted.
- No live Terraform apply is part of module implementation.
- Do not place API tokens or rendered Secret values in Terraform, tests,
  documentation, outputs, or command output.
