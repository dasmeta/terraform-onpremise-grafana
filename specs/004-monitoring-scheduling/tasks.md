# Tasks: Preserve monitoring scheduling values

**Input**: `specs/004-monitoring-scheduling/spec.md` and `plan.md`

## Phase 1: Regression coverage

- [x] T001 [US1] Create isolated mocked Helm-provider tests in `tests/monitoring-scheduling` for Prometheus/Alertmanager, VictoriaMetrics, Tempo, and Loki.
- [x] T002 [US1] Run the focused test and record the red result against `v1.28.5` (the baseline rejects heterogeneous Prometheus Helm values before final composition).

## Phase 2: Preserve native Helm values precedence

- [x] T003 [US1] Normalize Prometheus `extra_configs` before inspection so heterogeneous Prometheus/Alertmanager values plan successfully.
- [x] T004 [US1] Re-run the focused regression test and verify the Prometheus/Alertmanager assertion turns green.
- [x] T005 [US1] Verify VictoriaMetrics caller scheduling and its later cluster endpoint contract remain ordered Helm values documents.
- [x] T006 [US1] Verify Tempo caller scheduling and its later metrics-generator/ServiceMonitor contract remain ordered Helm values documents.
- [x] T007 [US1] Verify Loki caller scheduling and its later monitoring contract remain ordered Helm values documents.
- [x] T008 [US1] Re-run the focused regression test and verify all scheduling and contract assertions turn green without a new provider dependency.

## Phase 3: Compatibility and handoff

- [x] T009 [US2] Update `README.md` to document scheduling through existing `extra_configs` maps and module-owned integration precedence.
- [x] T010 [US2] Run formatting, root validation, and focused scheduling tests; inspect the diff for public-interface changes. The legacy collector-selection filter exits successfully but discovers zero tests, so it is not counted as executed regression coverage.
- [ ] T011 Commit the feature package, tests, implementation, and README using a conventional patch-fix message.
