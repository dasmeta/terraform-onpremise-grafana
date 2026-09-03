# Tasks: Selectable Metrics Collectors with VictoriaMetrics Operator

**Input**: Design documents from
`specs/004-metrics-collector-selection/` and the detailed implementation plan
at
`docs/superpowers/plans/2026-08-28-victoria-metrics-operator-collector-support.md`
**Prerequisites**: `spec.md`, `plan.md`, `research.md`, `data-model.md`,
`contracts/metrics-collector-contract.md`, and `quickstart.md`

**Tests**: Required by SC-005, SC-006, and SC-010 through SC-017. Add each
behavioral test before its implementation and confirm that it fails for the
expected reason.

**Git constraint**: Do not run `git add`, commit, reset, checkout, worktree, or
other git-mutating commands.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel because it uses a disjoint file and does not
  depend on an incomplete task.
- **[Story]**: Maps to a user story in `spec.md`.
- Every task names the exact file it changes or verifies.

## Phase 1: Setup (Shared Test Contract)

**Purpose**: Prepare focused fixtures and split the existing large assertion
file before implementing Operator resources.

- [X] T001 Add reusable Operator/VMAgent fixture inputs and defaults in `tests/metrics-collector-selection/0-setup.tf`
- [X] T002 Update the fixture module call to pass `victoria_metrics.operator` and the revised `victoria_metrics.agent` object in `tests/metrics-collector-selection/1-example.tf`
- [X] T003 Split `tests/metrics-collector-selection/2-assertions.tftest.hcl` into independently runnable `tests/metrics-collector-selection/2-root-contract.tftest.hcl`, `tests/metrics-collector-selection/3-operator-values.tftest.hcl`, and `tests/metrics-collector-selection/4-generated-objects.tftest.hcl`, each with its own Helm mock and the root-contract file with its additional Grafana mock provider
- [X] T004 Document exact initialization/test commands and the three focused assertion responsibilities in `tests/metrics-collector-selection/README.md`

---

## Phase 2: Foundational (Blocking Input and Validation Contract)

**Purpose**: Establish valid public/child interfaces and deterministic invalid
state guards without leaving an unloadable intermediate module.

**⚠️ CRITICAL**: Complete this phase before implementing story resources.

- [X] T005 Write failing tests for VMAgent names `Invalid_Name`, `a..b`, and `a.-b`, replica counts `0`, `-1`, and `1.5`, and Victoria mode without Prometheus CRD ownership in `tests/metrics-collector-selection/2-root-contract.tftest.hcl`
- [X] T006 Atomically replace the root standalone-agent shape, add described Operator/VMAgent/KSM child inputs while temporarily retaining standalone-only child inputs, and update plus order the root VM child after Prometheus/KSM modules in `variables.tf`, `modules/victoria-metrics/variables.tf`, and `main.tf`
- [X] T007 Strengthen the selected-backend precondition to require Prometheus and VictoriaMetrics releases for Victoria conversion mode in `outputs.tf`
- [X] T008 Run the focused suite and record GREEN validation cases plus still-RED Operator resource cases in `tests/metrics-collector-selection/README.md`

**Checkpoint**: Revised inputs load successfully; malformed names/replicas and
unsupported CRD ownership fail at the public boundary.

---

## Phase 3: User Story 1 - Both Backends with Prometheus Active (Priority: P1) 🎯 MVP

**Goal**: Install VictoriaMetrics Operator while Prometheus remains the only
scraper and remote-writes a validation copy to the unchanged VM cluster.

**Independent Test**: Plan both backends with
`metrics_collector = "prometheus"`; assert Prometheus active, Operator
installed, no VMAgent, remote write enabled, both datasources present, and
existing VM storage values unchanged.

### Tests for User Story 1

- [X] T009 [US1] Add failing root assertions for Operator installed, VMAgent disabled/null, Prometheus active, remote write enabled, both provisioned Grafana datasource map entries with exactly one selector-owned default, and stable VM storage in `tests/metrics-collector-selection/2-root-contract.tftest.hcl`
- [X] T010 [P] [US1] Add failing child assertions for chart `victoria-metrics-operator` version `0.67.2`, conversion ownership, top-level watch, empty `controller.disableReconcileFor`, protected CRD/RBAC values, and empty `extraObjects` in `tests/metrics-collector-selection/3-operator-values.tftest.hcl`

### Implementation for User Story 1

- [X] T011 [US1] Define protected Operator values with nested conversion flags, top-level watch, an empty `controller.disableReconcileFor` that preserves unrelated args, required RBAC/CRDs, disabled CRD cleanup, an empty Prometheus-mode object list, and transition-only aliases that keep the old standalone resource loadable until T012 in `modules/victoria-metrics/locals.tf`
- [X] T012 [US1] Remove `helm_release.vmagent`, its temporary child-only variables, and the transition-only `agent_scrape_configs`/`agent_extra_configs` aliases, then add `helm_release.victoria_metrics_operator` after the unchanged cluster release in `modules/victoria-metrics/main.tf`, `modules/victoria-metrics/locals.tf`, and `modules/victoria-metrics/variables.tf`
- [X] T013 [P] [US1] Add only a filtered Operator release identity and never `helm_release.metadata` to `modules/victoria-metrics/outputs.tf`
- [X] T014 [US1] Report exact Operator-installed and VMAgent-disabled semantics without raw values in `locals.tf` and `outputs.tf`
- [X] T015 [US1] Make the complete Prometheus-first root/child assertions GREEN in `tests/metrics-collector-selection/2-root-contract.tftest.hcl` and `tests/metrics-collector-selection/3-operator-values.tftest.hcl`

**Checkpoint**: First rollout apply installs conversion infrastructure while
Prometheus remains the sole active scraper.

---

## Phase 4: User Story 4 - Independent kube-state-metrics (Priority: P1)

**Goal**: Keep the exporter independent and render exactly one
collector-specific scrape path with a scoped 32 MiB VictoriaMetrics limit.

**Independent Test**: Prometheus mode has one standalone ServiceMonitor and no
native VM object; Victoria mode has no ServiceMonitor and exactly one exact
`VMServiceScrape`; a caller KSM job suppresses that object.

### Tests for User Story 4

- [X] T016 [US4] Add failing Victoria assertions for exactly one native `VMServiceScrape`, exact default and custom namespace/release/Service-fullname-derived identities, selectors/port/honor-label/32 MiB fields, and no default inline KSM job in `tests/metrics-collector-selection/4-generated-objects.tftest.hcl`
- [X] T017 [US4] Add a failing caller-job suppression test expecting zero native KSM objects, exactly the unchanged caller inline job, and no injected size limit in `tests/metrics-collector-selection/4-generated-objects.tftest.hcl`
- [X] T018 [P] [US4] Add Prometheus assertions for exactly one standalone ServiceMonitor and zero native KSM objects in `tests/metrics-collector-selection/2-root-contract.tftest.hcl`

### Implementation for User Story 4

- [X] T019 [US4] Normalize caller jobs, detect the exact `kube-state-metrics` job name, and remove the former generated static job in `modules/victoria-metrics/locals.tf`
- [X] T020 [US4] Generate the conditional namespaced `VMServiceScrape` with a collision-safe name derived from the resolved Service fullname, exact Service labels, port `http`, `honorLabels`, and endpoint `max_scrape_size` in `modules/victoria-metrics/locals.tf`
- [X] T021 [US4] Forward the resolved exporter namespace, release name, and fullname and derive matching status in `main.tf` and `locals.tf`
- [X] T022 [US4] Expose mutually exclusive ServiceMonitor/native-object state without raw object data in `outputs.tf`
- [X] T023 [US4] Make default/custom identity, exact count, 32 MiB scope, no-static-job, and suppression tests GREEN in `tests/metrics-collector-selection/2-root-contract.tftest.hcl` and `tests/metrics-collector-selection/4-generated-objects.tftest.hcl`

**Checkpoint**: kube-state-metrics remains installed in both modes with one
converged scrape path.

---

## Phase 5: User Story 5 - Reuse Application Monitor Objects (Priority: P1)

**Goal**: Let Operator conversion and an operator-managed VMAgent reuse existing
application monitors, including Secret-backed authorization, without a duplicate
manual job.

**Independent Test**: Operator safety fields cannot be overridden; one VMAgent
selects all converted objects; non-secret exceptional jobs become exact inline
YAML; the module has no application credential input or generated auth config.

### Tests for User Story 5

- [X] T024 [US5] Add failing precedence assertions for conversion flags, conflicting controller-disable/watch env plus preserved unrelated env/arg, empty `envFrom`, owner references, top-level cluster watch, RBAC, CRDs, cleanup, and generated objects in `tests/metrics-collector-selection/3-operator-values.tftest.hcl`
- [X] T025 [US5] Add failing protected VMAgent activation/name/replica/select-all/Pod-Service selector/remote-write/inline-config assertions in `tests/metrics-collector-selection/4-generated-objects.tftest.hcl`
- [X] T026 [US5] Rewrite the old standalone-resource test as failing generated-VMAgent assertions for resource defaults, 16 queues, nested partial overrides, and unchanged non-secret caller jobs with no `helm_release.vmagent` reference in `tests/metrics-collector-selection/4-generated-objects.tftest.hcl`
- [X] T027 [P] [US5] Before implementation, add module-boundary assertions for enabled conversion, exact non-auth inline input, and no application credential variable without blacklisting valid payload/Secret-selector key names in `tests/metrics-collector-selection/3-operator-values.tftest.hcl` and `modules/victoria-metrics/variables.tf`

### Implementation for User Story 5

- [X] T028 [US5] Implement explicit protected-key filtering plus nested request/limit/extraArg default merges in `modules/victoria-metrics/locals.tf`
- [X] T029 [US5] Generate one selector-controlled `VMAgent` with `selectAllByDefault`, derived vminsert URL, exact resource/queue values, and YAML-encoded caller jobs in `modules/victoria-metrics/locals.tf`
- [X] T030 [US5] Apply raw Operator values before protected conversion/ownership/top-level-watch/filtered-env/empty-envFrom/controller-enable/RBAC/CRD/`extraObjects` values in `modules/victoria-metrics/main.tf`
- [x] T031 [P] [US5] Document monitor conversion, protected env/envFrom and Pod-Service selectors, generated config Secret behavior, wildcard Secret verbs in chart `0.67.2`, service-account restrictions, and forbidden inline credential values in `modules/victoria-metrics/README.md`
- [X] T032 [US5] Make all protected merge and generated VMAgent assertions GREEN in `tests/metrics-collector-selection/3-operator-values.tftest.hcl` and `tests/metrics-collector-selection/4-generated-objects.tftest.hcl`

**Checkpoint**: Terraform remains outside the credential path; live checks,
not fabricated tokens, will verify source-to-converted Secret selectors.

---

## Phase 6: User Story 2 - Switch Collection to VictoriaMetrics (Priority: P2)

**Goal**: Activate VMAgent and disable Prometheus scraping while preserving
VictoriaMetrics history, PVC identity, and Grafana query access.

**Independent Test**: Victoria mode has one VMAgent, Prometheus server disabled,
VM datasource default, derived write URL, native KSM object, and unchanged
cluster/PVC inputs.

### Tests for User Story 2

- [X] T033 [US2] Add failing Victoria-selected root assertions for one VMAgent, disabled Prometheus server, both Grafana datasource entries with only VictoriaMetrics default, native KSM state, and derived write URL in `tests/metrics-collector-selection/2-root-contract.tftest.hcl`
- [X] T034 [US2] Before selector implementation, add paired Prometheus/Victoria child runs proving cluster release, retention, vmstorage replicas, class, size, and access modes are selector-independent in `tests/metrics-collector-selection/4-generated-objects.tftest.hcl`

### Implementation for User Story 2

- [X] T035 [US2] Complete selector-controlled Prometheus server, VMAgent activation, and datasource wiring in `locals.tf` and `main.tf`
- [x] T036 [US2] Preserve selector-owned Prometheus server and bundled KSM disablement after raw chart values in `modules/prometheus/main.tf`
- [x] T037 [P] [US2] Document active/inactive scraper behavior and retained release components in `modules/prometheus/README.md`
- [X] T038 [US2] Add exact VMAgent enabled/name, native KSM state, derived write URL, and datasource UID status without raw values in `outputs.tf`
- [X] T039 [US2] Run and record an exit-0, `0 failed` collector-switch and storage-stability suite in `tests/metrics-collector-selection/README.md`

**Checkpoint**: Both converged selector modes have exactly one scraper and
unchanged VictoriaMetrics storage.

---

## Phase 7: User Story 3 - Safe Configuration and AWS Wrapper Support (Priority: P3)

**Goal**: Give base and AWS users one contract, clear errors, and an executable
two-apply rollout/rollback.

**Independent Test**: Use a sentinel `terraform console` probe to prove the
wrapper preserves nested values, validate both examples, and follow documented
queue gates from Prometheus-first preparation through switch and rollback.

### Tests and Implementation for User Story 3

- [x] T040 [US3] Update the root Operator/VMAgent example, validation matrix, two-apply rollout, queue gates, bounded transition, and rollback in `README.md`
- [x] T041 [P] [US3] Document independent exporter and native VM monitor ownership in `modules/kube-state-metrics/README.md`
- [x] T042 [US3] Obtain write approval, preserve existing dirty state, and add non-secret sentinel inputs including required `cluster_name` in `../terraform-aws-grafanav12/tests/metrics-collector-selection/contract.tfvars`
- [x] T043 [US3] Run the pre-schema unsupported-attribute RED console probe from `../terraform-aws-grafanav12` using `tests/metrics-collector-selection/contract.tfvars`
- [x] T044 [US3] Replace the wrapper nested object with the exact Operator/VMAgent shape and matching DNS/replica validations in `../terraform-aws-grafanav12/variables.tf`
- [x] T045 [US3] Prove direct `metrics_collector` and `victoria_metrics` forwarding and absence of wrapper monitoring resources in `../terraform-aws-grafanav12/main.tf`
- [x] T046 [US3] Set the AWS base example to both-installed Prometheus-first mode in `../terraform-aws-grafanav12/tests/base/1-example.tf`
- [x] T047 [US3] Set the AWS Victoria example to the identical backend object with only the selector changed in `../terraform-aws-grafanav12/tests/base-with-victoria-metrics/1-example.tf`
- [x] T048 [US3] Synchronize wrapper rollout/security/KSM/CRD ownership docs in `../terraform-aws-grafanav12/README.md`, `../terraform-aws-grafanav12/docs/superpowers/specs/2026-08-20-aws-wrapper-metrics-collector-selection-design.md`, and every file under `../terraform-aws-grafanav12/specs/003-metrics-collector-selection/`
- [x] T049 [US3] Run the GREEN sentinel console probe plus initialized wrapper root/base/VM example validations and record commands in `../terraform-aws-grafanav12/tests/base-with-victoria-metrics/README.md`
- [x] T050 [US3] Record that registry-source restoration is blocked until an exact published base-module version is supplied in `../terraform-aws-grafanav12/README.md`

**Checkpoint**: Base and wrapper accept and forward the same values; the wrapper
owns no Operator/VMAgent/scrape resources and no release version is invented.

---

## Phase 8: Polish and Cross-Cutting Verification

**Purpose**: Prove source, rendering, docs, and rollout checks are consistent.

- [x] T051 [P] Remove stale standalone-agent wording from active files only in `README.md`, `modules/`, `tests/metrics-collector-selection/`, `../terraform-aws-grafanav12/README.md`, and `../terraform-aws-grafanav12/tests/`
- [x] T052 Run focused Terraform formatting without rewriting unrelated files in `variables.tf`, `locals.tf`, `main.tf`, `outputs.tf`, `modules/prometheus/`, `modules/victoria-metrics/`, `modules/kube-state-metrics/`, and `tests/metrics-collector-selection/`
- [x] T053 Initialize with `-backend=false -lockfile=readonly`, validate the root, and run the complete exit-0, `0 failed` native suite in `/Users/vazgen/work/Dasmeta/modules/terraform-onpremise-grafana` and `tests/metrics-collector-selection/`
- [x] T054 Add the non-secret, render-only chart fixture with `admissionWebhooks.enabled = false` in `tests/metrics-collector-selection/operator-render-values.yaml`
- [x] T055 In one fail-fast shell with guaranteed exact-path cleanup, render Operator chart `0.67.2` with `--include-crds` to a restricted temporary file and inspect both required CRDs, no Secret/controller-disable/watch-env path, wildcard Secret RBAC, VMAgent, and VMServiceScrape predicates against `specs/004-metrics-collector-selection/contracts/metrics-collector-contract.md`
- [x] T056 Prove the standalone `helm_release.vmagent` plus obsolete dotted, child-variable, and nested-agent fields are absent from active Terraform source and examples in both repositories using the exact single-line and multiline searches in `docs/superpowers/plans/2026-08-28-victoria-metrics-operator-collector-support.md`
- [x] T057 Validate Prometheus queue drain, VMAgent queue drain, source/converted auth selectors, target health, duplicate-scrape, and PVC identity procedures in `specs/004-metrics-collector-selection/quickstart.md`
- [x] T058 Run read-only `git diff --check`, `git diff --cached --check`, and `git status --short` in both repositories without staging or mutating either worktree
- [x] T059 Add regression coverage and a nested merge so selector-owned Prometheus validation `remoteWrite` preserves all sibling `prometheusSpec` overrides
- [x] T060 Protect kube-prometheus-stack monitor CRD enablement from raw values while the release owns conversion source CRDs
- [x] T061 Add regression coverage and a final VictoriaMetrics cluster endpoint contract so raw values cannot invalidate derived vminsert/vmselect URLs
- [x] T062 Give the native kube-state-metrics VMServiceScrape a distinct suffix and regression coverage to avoid Helm ownership collision with the converted ServiceMonitor during handoff

---

## Phase 9: Fresh-cluster Operator CRD Bootstrap Regression

**Purpose**: Ensure a single fresh-cluster apply installs VictoriaMetrics CRDs
before Helm REST-maps the generated VMAgent and VMServiceScrape objects.

- [X] T063 Trace the first-install failure to chart `0.67.2` templated CRDs and record the supported plain-CRD path in `specs/004-metrics-collector-selection/research.md`
- [X] T064 Add a failing caller-override regression assertion for protected `crds.plain` and `crds.upgrade.enabled` values in `tests/metrics-collector-selection/3-operator-values.tftest.hcl`
- [X] T065 Protect Helm pre-install CRD bootstrap and the chart-provided CRD upgrade hook in `modules/victoria-metrics/locals.tf`
- [X] T066 Align the Operator contract and usage documentation in `modules/victoria-metrics/README.md` and `README.md`
- [X] T067 Run focused Terraform tests, pinned Helm CRD/custom-resource rendering, validation, formatting, and diff checks without git mutation

---

## Dependencies and Execution Order

### Phase dependencies

- **Phase 1** starts immediately.
- **Phase 2** depends on Phase 1 and blocks every user story.
- **US1 (Phase 3)** is the migration MVP.
- **US4 (Phase 4)** depends on the Operator object-list foundation from US1.
- **US5 (Phase 5)** depends on US1 and the object pattern from US4.
- **US2 (Phase 6)** depends on US1, US4, and US5 because it activates VMAgent.
- **US3 (Phase 7)** depends on the stable base contract and requires sibling
  repository write approval.
- **Phase 8** depends on all implemented stories.

### User story completion order

```text
Foundation
  -> US1 Prometheus-first Operator install
      -> US4 independent KSM/native scrape
          -> US5 monitor conversion + VMAgent
              -> US2 Victoria collector switch
                  -> US3 validation + AWS wrapper
                      -> Final verification
```

The exactly-one-scraper guarantee applies after convergence. Separate Helm
releases make a bounded overlap or collection gap possible during selector
handoff.

### Parallel opportunities

- T010 can proceed independently from root test T009.
- T018 can proceed while Victoria-specific KSM tests T016-T017 are written.
- T027 and T031 use disjoint test/documentation files.
- T037 can proceed while root Victoria wiring is completed.
- T041 is independent after the KSM contract is stable.
- T051 can be divided by repository/file group after all behavior is GREEN.

## Implementation Strategy

### MVP first

Complete Phases 1-3 and deploy the Prometheus-first state. This installs the
Operator while preserving Prometheus as the only active scraper and leaves the
existing VictoriaMetrics cluster/PVCs unchanged.

### Incremental delivery

1. Establish validated inputs and safe Prometheus-first Operator installation.
2. Replace the KSM static job with one selector-specific native object.
3. Add protected VMAgent generation and monitor conversion support.
4. Switch collection only after Prometheus queue and converted-target gates pass.
5. Mirror the stable contract into the AWS wrapper.
6. Perform render, source, docs, and live rollout verification.

### Definition of done

- All 67 tasks are complete or an explicitly external release gate is recorded.
- Root and wrapper validations pass after initialization.
- Focused Terraform tests exit 0 with `0 failed`.
- Rendered chart predicates pass without producing or printing a Secret.
- Live success is claimed only after target, metric, queue, duplicate, and PVC
  evidence is observed.
- No git mutation was performed by this work.
