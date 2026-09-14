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
kube-prometheus-stack `75.8.0`, kube-state-metrics `7.8.1`,
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
remain stable; Operator/CRD/RBAC installation must be explicit; no Git
mutations
**Scale/Scope**: Two selectable metrics backends, two shared exporters, three
native node scrape paths, six optional Kubernetes component scrape paths, and
collector-aware Grafana/Tempo/Loki integrations

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
  explicit. Migration documentation also records the non-atomic KSM Helm
  ownership transfer, node-exporter replacement, Prometheus CR/StatefulSet
  removal, and mandatory PVC inventory.
- **Secret safety — PASS**: native node auth uses the mounted service-account
  token; no credential values enter outputs, tests, or examples.
- **Override safety — PASS**: selector-owned values are final while unrelated
  caller chart settings remain configurable.
- **Backward compatibility — PASS**: Prometheus-only defaults remain valid and
  the dual-backend migration path remains available. Existing VictoriaMetrics
  storage-only consumers do not receive a new Operator or cluster-wide RBAC
  unless they opt in.
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
7. Replace kube-prometheus-stack-owned Kubernetes component Services and
   ServiceMonitors with standalone-only native Service/VMServiceScrape pairs.
8. Make kubelet/cAdvisor discovery selector-owned in dual-backend mode: the
   Prometheus kubelet ServiceMonitor is enabled only for Prometheus selection,
   while VictoriaMetrics selection uses the existing native VMNodeScrapes.

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

Add `enabled = optional(bool, false)` inside the existing grouped
`victoria_metrics.operator` object. This is a narrow optional interface
extension supported by the module's Terraform `~> 1.3` constraint; it does not
broaden provider passthrough or require a provider/version change. Gate
converter and agent status with the resolved Operator installation state, and
reject VictoriaMetrics collector selection unless both cluster and Operator
are enabled.

### Child-module changes

- Prometheus: force both bundled exporters off after raw values.
- node-exporter: install a pinned DaemonSet/Service with selector-owned monitor
  behavior, current resources, metric filtering, and no annotation scrape.
- VictoriaMetrics: split Operator/CR-instance releases, condition the converter,
  generate VMAgent/VMServiceScrape/VMNodeScrape objects, protect selectors, and
  suppress cluster component Prometheus monitors in VM-only mode. Apply the
  same explicit Operator gate to both Operator-related Helm releases and return
  null/empty child outputs when they are absent.
- Tempo/Loki/Grafana: protect monitor generation and derive selected backend
  integration values without overriding explicit caller destinations.

### In-place migration safety

Document the first upgrade as a complete, non-targeted root apply. The existing
kube-state-metrics fullname is retained while its Helm owner changes; the
node-exporter fullname changes; and selecting VictoriaMetrics removes the
Prometheus custom resource and generated StatefulSet even if the parent Helm
release remains installed. Require pre/post object and PVC inventories, state
that Prometheus history is unavailable while its server is absent, and provide
recovery only for an exact stale object after ownership annotations are
verified. PVC and CRD deletion are never recovery steps.

### Verification

Run focused tests after each story, then format, validate, run all available
module tests, inspect rendered Helm values/manifests for Prometheus API absence,
and run `git diff --check`. Do not run apply against the user's cluster and do
not stage or commit changes.

### Endpoint-specific native node metric filters

Keep the existing `agent_kubelet_metrics` input as a backward-compatible union
of node metric patterns. Internally classify known patterns by the kubelet,
cAdvisor, and resource endpoints that expose them. Known KSM/scheduler-only
patterns map to no node endpoint, while unknown caller patterns retain the old
behavior and are added to every enabled endpoint. Remove dead patterns from the
root and child defaults and replace `pod_memory_usage_bytes` with the kubelet
resource endpoint's `pod_memory_working_set_bytes` metric.

Verify exact endpoint regexes in focused Terraform tests before running the
complete collector-selection suite. No live apply or Git mutation is part of
this remediation.

### Native node TLS intent cleanup

The current kubelet, cAdvisor, and resource `VMNodeScrape` objects set both the
service-account CA path and `insecureSkipVerify = true`. The CA cannot
participate in target certificate validation while validation is disabled, so
the generated configuration communicates two conflicting intents.

Preserve current connectivity behavior by keeping `insecureSkipVerify = true`
and removing only the redundant `caFile` from native node scrapes. Do not alter
the API-server or Kubernetes component TLS paths: those either verify with a
CA or expose an explicit caller-controlled compatibility choice. This is an
improve-mode cleanup with no new ability, public input, provider constraint,
upstream-module choice, interface widening, or breaking behavior. Existing
wrapper boundaries and repository Terraform layout remain unchanged. Shared
governance comes from the Terraform module developer constitution references,
and the existing `specs/005-victoria-metrics-native-stack` package satisfies
the downstream module-change gate.

Update the focused generated-object assertion first and observe it fail on the
present `caFile`. Then remove the field, synchronize node-TLS documentation,
and run focused/full Terraform tests plus format, validation, YAML,
terraform-docs, and diff checks. Do not apply infrastructure or mutate Git.

### Caller-owned service scrape ownership

`agent.extra_scrape_configs` currently recognizes only the exact
`kube-state-metrics` transition job. The VictoriaMetrics child already has
individual booleans for rendering KSM, node-exporter, Tempo, and Loki
`VMServiceScrape` objects, but the root module does not expose an independent
way to suppress those objects while retaining their workloads. Consequently a
root caller that supplies an inline job for node-exporter, Tempo, or Loki can
also receive the generated native scrape path.

Three approaches were evaluated:

- infer ownership from reserved inline `job_name` values for every component;
  rejected because job names are caller-controlled and cannot reliably prove
  that two jobs target the same endpoint;
- reuse workload or Prometheus-monitor enable flags; rejected because scrape
  ownership must be independently selectable and node-exporter cannot remain
  installed through that path;
- add one grouped root input containing explicit module-owned service-scrape
  switches; selected because intent is deterministic and each workload remains
  independent.

Add `victoria_metrics.agent.managed_service_scrapes` with optional,
default-`true` booleans for `kube_state_metrics`, `node_exporter`, `tempo`, and
`loki`. Combine each switch with its existing root eligibility condition and
pass the resolved result through the existing child booleans. A `false` value
suppresses only that generated `VMServiceScrape`; it does not disable a Helm
release, Prometheus-mode monitor, or caller `inlineScrapeConfig`. Retain the
exact KSM job-name suppression as a backward-compatible transition behavior.

This is a narrow grouped interface extension approved by the user on
2026-09-14. All fields are optional and preserve current defaults, so it is not
a breaking change or broad upstream pass-through. The grouped boundary is
unambiguous because all four fields control module-owned service discovery.
Terraform optional object attributes are supported by the existing `~> 1.3`
constraint, so the Modern Capabilities classification is `supported`. No
provider, chart, resource type, version constraint, repository automation, or
upstream-module decision changes. Existing repository layout and wrapper
boundaries remain intact. Shared governance comes from the Terraform module
developer constitution references, and the active
`specs/005-victoria-metrics-native-stack` package remains the module-change
gate evidence.

Add the root regression test first and observe node-exporter, Tempo, and Loki
remain enabled. Then implement the grouped gates, document the opt-out example,
regenerate Terraform input tables, and run focused/full tests, formatting,
validation, YAML, documentation, and diff checks. Do not apply infrastructure
or mutate Git state.

### Published VictoriaMetrics Cluster chart default

The root module already pins and forwards VictoriaMetrics Cluster chart
`0.31.0`, but the directly consumable child module defaults to unpublished
cluster chart `0.31.4`. The upstream index contains `0.31.0` followed by
`0.32.0`; `0.31.4` belongs to the separate `victoria-metrics-k8s-stack`
chart. A root consumer is currently protected by the explicit forwarding,
while a direct child consumer can fail Helm chart resolution.

Keep the established root pin and align only the child default and generated
child documentation to `0.31.0`. Do not introduce a chart upgrade to `0.32.0`
in this remediation. Add a direct-child regression plan first, observe it
resolve the old default, then apply the one-value correction and run the
focused and complete Terraform checks. This is an improve-mode bug fix with
no public interface expansion, provider constraint change, breaking behavior,
or Git mutation.

## Complexity Tracking

No gate violations require justification.

The Modern Capabilities Rule classifies this optional grouped gate as
`supported`: Terraform optional object attributes and resource `count` are
already available within the existing version constraints. No upstream module,
provider capability, version bump, automation change, or scratch-template
fallback is involved. Shared governance comes from the Terraform module
developer constitution references; repository-specific behavior remains in
this Speckit package.
