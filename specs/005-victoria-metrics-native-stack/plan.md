# Implementation Plan: VictoriaMetrics Native Stack

**Branch**: `005-victoria-metrics-native-stack` (branch creation skipped by
user request) | **Date**: 2026-08-31 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from
`/specs/005-victoria-metrics-native-stack/spec.md`

## Summary

Allow `metrics_collector = "victoria_metrics"` with Prometheus fully disabled.
The module will install official VictoriaMetrics CRDs before VM custom-resource
instances, use one Operator-managed VMAgent with native VM discovery, split
node-exporter out of kube-prometheus-stack alongside the existing independent
kube-state-metrics release, and make Grafana/Tempo/Loki integration values
collector-aware. Dual-backend migration remains supported with one active
scraper and conditional Prometheus monitor conversion.

## Technical Context

**Language/Version**: Terraform HCL compatible with Terraform `~> 1.3`; native
test fixtures use Terraform `>= 1.7, < 2.0`  
**Primary Dependencies**: Helm provider `~> 2.17`, Grafana provider `~> 4.0`,
kube-prometheus-stack `75.8.0`, kube-state-metrics `6.1.0`,
prometheus-node-exporter `4.47.1`, VictoriaMetrics Cluster `0.31.0`,
VictoriaMetrics Operator `0.67.2`, Tempo `1.23.3`, Loki `6.34.0`  
**Storage**: Existing Prometheus PVC and VictoriaMetrics vmstorage PVC contracts;
no new stateful storage type  
**Testing**: `terraform fmt`, `terraform validate`, native `terraform test` with
mocked providers, pinned Helm template/render inspection  
**Target Platform**: Kubernetes `>= 1.25` as required by the pinned VM Operator
chart; EKS is a supported Kubernetes target but not hard-coded  
**Project Type**: Reusable Terraform root module with local child modules and
module-local Helm chart  
**Performance Goals**: Exactly one active scraper; no duplicate module-managed
targets; preserve current metric filtering and configurable VMAgent resources  
**Constraints**: VM-only cannot depend on `monitoring.coreos.com`; credentials
cannot be copied into Terraform state; persistent VictoriaMetrics identity must
remain stable; no Git mutations  
**Scale/Scope**: Two selectable metrics backends, two shared exporters, three
native node scrape paths, and collector-aware Grafana/Tempo/Loki integrations

## Constitution Check

*GATE: Passed before Phase 0 and re-checked after Phase 1.*

The repository constitution file is an unfilled template, so the applicable
module-development standards and approved design are used as the gates:

- **Public contract first — PASS**: [spec.md](spec.md) and
  [contracts/metrics-stack-contract.md](contracts/metrics-stack-contract.md)
  define inputs, outputs, compatibility, and failure modes.
- **No hidden dependency — PASS**: VM-only uses only VM Operator CRDs; the
  Operator and CR instances have an explicit release dependency.
- **Pinned upstreams — PASS**: every new chart is pinned; node-exporter matches
  the version already bundled by the current Prometheus stack.
- **Safe lifecycle — PASS**: no automatic CRD cleanup or VictoriaMetrics PVC
  replacement; independent exporter identity and transition ordering are
  explicit.
- **Secret safety — PASS**: native node auth uses mounted token/CA file paths;
  no credential values enter outputs, tests, or examples.
- **Override safety — PASS**: selector-owned values are final while unrelated
  caller chart settings remain configurable.
- **Backward compatibility — PASS**: Prometheus-only defaults remain valid and
  the dual-backend migration path remains available.
- **Test-first delivery — PASS**: each implementation phase starts with a
  failing native Terraform contract test.
- **Scope control — PASS**: wrapper/environment/application changes, alerting
  replacement, and destructive CRD cleanup remain outside this feature.

## Phase 0: Research

Research is complete in [research.md](research.md). Key decisions are:

1. Use the official VM Operator chart for CRDs and a dependent module-local
   Helm release for VM resource instances.
2. Use native VM discovery in standalone mode and conditional Prometheus
   conversion only during dual-backend migration.
3. Manage kube-state-metrics and node-exporter independently from both storage
   stacks.
4. Recreate kubelet/cAdvisor coverage with native `VMNodeScrape` resources.
5. Make module-owned monitors and Tempo remote write collector-aware.
6. Keep caller scrape migration and CRD cleanup explicit and manual.

## Phase 1: Design and Contracts

- [data-model.md](data-model.md) defines resolved entities, invariants, mode
  matrix, and migration transitions.
- [contracts/metrics-stack-contract.md](contracts/metrics-stack-contract.md)
  defines root inputs, generated resources, selector-owned values, outputs,
  and compatibility boundaries.
- [quickstart.md](quickstart.md) defines rollout, validation, rollback, and the
  application-migration gate.

Post-design constitution re-check: all gates remain passing. The explicit
resource-release boundary resolves the clean-cluster CRD ordering risk without
adding a provider or private CRD fork.

## Project Structure

### Documentation (this feature)

```text
specs/005-victoria-metrics-native-stack/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── metrics-stack-contract.md
└── tasks.md
```

### Source Code (repository root)

```text
.
├── locals.tf
├── main.tf
├── outputs.tf
├── variables.tf
├── README.md
├── modules/
│   ├── grafana/
│   ├── kube-state-metrics/
│   ├── loki-stack/
│   ├── node-exporter/                  # new independent exporter child
│   ├── prometheus/
│   ├── tempo/
│   └── victoria-metrics/
│       ├── charts/
│       │   └── resources/              # new local chart for VM CR instances
│       ├── locals.tf
│       ├── main.tf
│       ├── outputs.tf
│       └── variables.tf
└── tests/
    └── metrics-collector-selection/
        ├── 0-setup.tf
        ├── 1-example.tf
        ├── 2-root-contract.tftest.hcl
        ├── 3-operator-values.tftest.hcl
        ├── 4-generated-objects.tftest.hcl
        ├── 5-native-stack.tftest.hcl
        └── README.md
```

**Structure Decision**: Extend the existing single Terraform module layout.
Use one focused child module for the newly independent node-exporter and a
module-local Helm chart to create VM custom-resource instances only after the
Operator release. Extend the existing collector-selection test fixture so old
and new mode contracts are verified together.

## Implementation Strategy

### Test-first contract changes

Update the current VM-only expected-failure test into a successful root-plan
contract and add focused tests before implementation. Confirm each new test
fails for the expected missing behavior, then implement the smallest module
change that makes it pass.

### Root orchestration

Add the independent node-exporter input/module, derive monitor gates and stable
identities, relax VM-only validation, pass conditional converter/native scrape
inputs to VictoriaMetrics, and expand non-sensitive status outputs. Keep the
backend enable flags independent from the selected collector.

### Child-module changes

- Prometheus: force both bundled exporters off after raw values.
- node-exporter: install a pinned DaemonSet/Service with selector-owned monitor
  behavior, current resources, metric filtering, and no annotation scrape.
- VictoriaMetrics: split Operator/CR-instance releases, condition the converter,
  generate VMAgent/VMServiceScrape/VMNodeScrape objects, protect selectors, and
  suppress cluster component Prometheus monitors in VM-only mode.
- Tempo/Loki/Grafana: protect monitor generation and derive selected backend
  integration values without overriding explicit caller destinations.

### Verification

Run focused tests after each story, then format, validate, run all available
module tests, inspect rendered Helm values/manifests for Prometheus API absence,
and run `git diff --check`. Do not run apply against the user's cluster and do
not stage or commit changes.

## Complexity Tracking

No gate violations require justification.
