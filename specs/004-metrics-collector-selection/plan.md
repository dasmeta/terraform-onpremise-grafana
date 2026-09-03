# Implementation Plan: Selectable Metrics Collectors with VictoriaMetrics Operator

**Branch**: `DMVP-10446` (Speckit feature override:
`004-metrics-collector-selection`) | **Date**: 2026-08-28 | **Spec**:
[spec.md](./spec.md)
**Input**: Approved feature specification and
[operator design](../../docs/superpowers/specs/2026-08-20-metrics-collector-selection-design.md)

## Summary

Keep Prometheus and the existing VictoriaMetrics cluster independently
installable while one selector controls the active scraper. Replace the
standalone `victoria-metrics-agent` Helm release with VictoriaMetrics Operator
`0.67.2` and a selector-controlled `VMAgent` CR. Reuse application
`PodMonitor`/`ServiceMonitor` resources through Operator conversion, retain a
native `VMServiceScrape` only for kube-state-metrics' 32 MiB requirement, and
mirror the revised input contract in the AWS wrapper.

## Technical Context

**Language/Version**: Terraform HCL, production module constraint `~> 1.3`;
native test fixture uses Terraform `>= 1.7, < 2.0`
**Primary Dependencies**: `hashicorp/helm ~> 2.17`,
`grafana/grafana ~> 4.0`, kube-prometheus-stack `75.8.0`,
victoria-metrics-cluster `0.31.0`, victoria-metrics-operator `0.67.2`,
kube-state-metrics `6.1.0`
**Storage**: Existing VictoriaMetrics vmstorage PVCs and retention settings;
VMAgent queue remains ephemeral unless explicitly overridden
**Testing**: Terraform native tests with mocked Helm/Grafana providers,
`terraform fmt -check`, `terraform validate`, focused `terraform test`, Helm
template inspection, and live Kubernetes rollout checks
**Target Platform**: Kubernetes clusters compatible with the pinned Operator
chart, including AWS EKS through `terraform-aws-grafanav12`
**Project Type**: Terraform infrastructure module, reusable Helm child modules,
focused test fixture, and an AWS wrapper module
**Performance Goals**: One active scraper after convergence; 16 VMAgent
remote-write queues by default; scoped 32 MiB kube-state-metrics scrape limit;
no change to current VM ingestion/storage sizing
**Constraints**: Preserve Prometheus-only defaults and VM cluster/PVC identity;
do not expose application tokens in Terraform; require both backends for the
current conversion mode; no supported converged dual-scrape mode; no git staging
or commit operations
**Scale/Scope**: Root collector wiring, Prometheus and VictoriaMetrics child
modules, independent kube-state-metrics integration, focused tests and docs,
plus schema/examples in one AWS wrapper

## Constitution Check

The repository constitution is still an unratified placeholder, so it has no
project-specific enforceable gates. The established Terraform module standards
and approved feature specification provide the gates:

- **Requirements gate: PASS** — all behavior is mapped to FR-001 through FR-042
  and measurable success criteria.
- **No unresolved clarification gate: PASS** — chart version, CRD ownership,
  Secret flow, object selection, override precedence, rollout, and rollback are
  explicit.
- **Backward compatibility gate: PASS with documented correction** —
  `metrics_collector` still defaults to Prometheus; the unpublished standalone
  agent fields are replaced by the Operator/VMAgent schema before release.
- **Single ownership gate: PASS** — base module owns Kubernetes/Helm behavior;
  AWS wrapper only forwards inputs; application charts retain monitor and Secret
  ownership.
- **Storage safety gate: PASS** — selector changes do not modify the VM cluster,
  retention, or PVC fields.
- **Security gate: PASS with accepted chart boundary** — Secret values remain
  outside Terraform and inline scrape examples. Runtime conversion needs Secret
  reads; the pinned chart-owned ClusterRole grants wildcard Secret verbs, so
  Operator service-account and source/generated Secret access are explicitly
  restricted, documented, and live-tested. Narrower custom RBAC is deferred.
- **Testing gate: PASS** — tests are planned before implementation for valid
  modes, invalid combinations, protected values, KSM object shape, storage
  stability, and wrapper parity.
- **Workspace gate: PASS** — no worktree or git mutation is required. The AWS
  wrapper is outside the current writable root and will require explicit write
  approval during implementation.

Post-design re-check: PASS. No `NEEDS CLARIFICATION` items remain. There is no
`AGENTS.md` in this repository, so no Speckit agent-context marker is updated.

## Project Structure

### Documentation for this feature

```text
specs/004-metrics-collector-selection/
├── spec.md
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── metrics-collector-contract.md
├── checklists/
│   └── requirements.md
└── tasks.md

docs/superpowers/
├── specs/
│   └── 2026-08-20-metrics-collector-selection-design.md
└── plans/
    └── 2026-08-28-victoria-metrics-operator-collector-support.md
```

### Base module source and tests

```text
variables.tf
locals.tf
main.tf
outputs.tf
README.md

modules/prometheus/
├── main.tf
├── variables.tf
└── values/prometheus-values.yaml.tpl

modules/victoria-metrics/
├── main.tf
├── locals.tf
├── variables.tf
├── outputs.tf
└── README.md

modules/kube-state-metrics/
├── main.tf
├── locals.tf
├── variables.tf
├── outputs.tf
└── README.md

tests/metrics-collector-selection/
├── 0-setup.tf
├── 1-example.tf
├── 2-root-contract.tftest.hcl
├── 3-operator-values.tftest.hcl
├── 4-generated-objects.tftest.hcl
├── operator-render-values.yaml
└── README.md
```

### AWS wrapper source and tests

```text
../terraform-aws-grafanav12/
├── variables.tf
├── main.tf
├── README.md
└── tests/
    ├── base/1-example.tf
    └── base-with-victoria-metrics/1-example.tf
```

**Structure Decision**: Keep selector and installation semantics in the base
root module. Keep VM cluster and Operator Helm rendering together in
`modules/victoria-metrics`, because they share the derived vminsert endpoint
and namespace. Keep exporter deployment in its existing focused child module.
Do not add a second Operator module or duplicate resources in the AWS wrapper.

## Design and Implementation

### 1. Root input and validation contract

Replace the unpublished standalone agent object with:

```hcl
operator = optional(object({
  chart_version = optional(string, "0.67.2")
  release_name  = optional(string, "victoria-metrics-operator")
  extra_configs = optional(any, {})
}), {})

agent = optional(object({
  name                 = optional(string, "victoria-metrics-agent")
  replica_count        = optional(number, 1)
  extra_scrape_configs = optional(any, [])
  extra_configs        = optional(any, {})
}), {})
```

Validate the VMAgent name and positive integer replica count. Extend the selected
backend precondition so VictoriaMetrics collector mode also requires
`prometheus.enabled = true`, with an error naming Prometheus monitoring CRD
ownership.

### 2. Root wiring

Keep current datasource, remote-write, and Prometheus server selection logic.
Pass Operator chart fields, VMAgent fields, and resolved kube-state-metrics
namespace/release/fullname values to `modules/victoria-metrics`. Extend
`metrics_collector_status` with Operator installation, VMAgent CR name, and
native KSM scrape state without exposing Secret data. Add module-level
dependencies on Prometheus and independent kube-state-metrics so Operator
startup follows monitor CRD and custom exporter namespace creation.

### 3. VictoriaMetrics child module

Leave `helm_release.victoria_metrics` unchanged. Remove
`helm_release.vmagent` and add `helm_release.victoria_metrics_operator`:

- chart `victoria-metrics-operator`, version from the revised input;
- raw chart values first;
- protected converter and ownership values under `operator`, plus top-level
  `watchNamespaces = []`, an empty `controller.disableReconcileFor` argument,
  filtered control env, empty `envFrom`, RBAC, Helm pre-install plain CRDs,
  the CRD upgrade hook, CRD cleanup safety, and `extraObjects` values last;
- no CRD cleanup during selector changes or rollback.

The pinned chart defaults `crds.plain = false`, which renders CRDs as ordinary
templates in the same manifest as `extraObjects`. A fresh cluster cannot build
REST mappings for `VMAgent` or `VMServiceScrape` in that ordering. Protect
`crds.plain = true` so Helm installs the dependency CRDs before regular
resources, and protect `crds.upgrade.enabled = true` so later chart upgrades
server-side apply updated plain CRDs.

Build one VMAgent object only when the selector enables it. Its protected spec
contains `selectAllByDefault`, positive replica count, the derived vminsert URL,
and YAML-encoded caller scrape jobs. Remove raw Pod/Service scrape and namespace
selectors so they cannot narrow discovery. Preserve existing resource and queue
defaults with nested partial override behavior for non-protected fields.

### 4. Monitor conversion and credentials

No application token is added to module inputs. Conversion remains enabled and
owner references are enabled. Automated tests assert chart settings and exact
non-authenticated inline input; they do not blacklist valid Secret-selector key
names. Live checks prove:

- source monitor and converted object coexist;
- authorization type and Secret selector are preserved;
- VMAgent target is healthy;
- Secret rotation is reconciled;
- missing/forbidden Secrets produce a visible target error.

### 5. kube-state-metrics exception

Keep the independent exporter and its Prometheus ServiceMonitor behavior. Remove
the static generated vmagent job. In VM mode, add a native
`VMServiceScrape` to Operator `extraObjects` with:

- object name `<resolved Service fullname>-victoria-metrics`, distinct from the
  same-name converter output during handoff;
- exporter namespace in metadata and `namespaceSelector.matchNames`;
- selector labels for exporter chart name and standalone release instance;
- endpoint port `http`, `honorLabels = true`, and
  `max_scrape_size = "32MiB"`.

If caller inline jobs contain `job_name = "kube-state-metrics"`, suppress the
native object and preserve the caller job unchanged.

### 6. Rollout and rollback

Document and test a two-apply migration:

1. Both enabled, Prometheus selected: install Operator, verify conversion, remove
   old standalone agent, keep Prometheus collecting/remote-writing.
2. Drain Prometheus remote write, select VictoriaMetrics: create VMAgent and
   disable Prometheus server.

Before rollback, drain the VMAgent queue. The exactly-one-scraper statement is a
converged-state invariant; documentation explicitly permits a bounded handoff
overlap or gap.

### 7. AWS wrapper parity

Mirror the exact revised nested object in the wrapper `variables.tf`, keep
`victoria_metrics = var.victoria_metrics` forwarding in `main.tf`, and update
the VictoriaMetrics example and generated input docs. Wrapper resources remain
out of scope.

## Testing Strategy

### Terraform native tests

- Prometheus-only remains valid and has no Operator.
- Both installed with Prometheus selected installs Operator, creates no VMAgent,
  retains remote write, and enables the KSM ServiceMonitor.
- Both installed with VictoriaMetrics selected disables the Prometheus server,
  creates one VMAgent, defaults Grafana to VM, and retains storage fields.
- VictoriaMetrics selected with Prometheus disabled fails with the CRD ownership
  message.
- Unsupported selector, disabled selected backend, invalid agent names including
  empty/malformed DNS labels (`a..b`, `a.-b`), and zero, negative, or fractional
  replica counts fail.
- Operator raw overrides cannot disable conversion/ownership through either the
  boolean, environment, `envFrom`, or `controller.disableReconcileFor`, narrow
  watching, disable required RBAC/CRDs, disable plain CRD bootstrap or its
  upgrade hook, enable cleanup, or replace generated objects.
- VMAgent raw overrides cannot replace name, replica count,
  `selectAllByDefault`, Pod/Service scrape or namespace selectors, remote-write
  URL, activation, or inline scrape jobs.
- Resource and queue defaults plus partial non-protected overrides remain
  correct.
- Native KSM VMServiceScrape renders exact namespace, selectors, port,
  honor-label flag, and 32 MiB endpoint limit.
- Caller KSM inline job suppresses the native object and remains unchanged.
- No standalone vmagent Helm release remains in source or planned resources.

### Static and rendering checks

- Focused `terraform fmt -check` and `terraform validate`.
- Focused fixture `terraform test`.
- `helm template --include-crds` the pinned Operator chart with a committed,
  non-secret render-only fixture and admission webhooks disabled; inspect only
  non-Secret CRDs, the chart's wildcard Secret RBAC, VMAgent, and
  VMServiceScrape render shape from a restricted temporary file.
- Validate AWS wrapper root and both collector examples after schema parity.
- Use a sentinel `terraform console` probe to prove wrapper object conversion
  preserves nested values that plain `terraform validate` could silently drop.
- Keep the wrapper's current local base-module source for validation; registry
  restoration waits for a real published base version and must not guess one.
- Run `git diff --check`; do not stage or commit.

### Live rollout checks

Follow [quickstart.md](./quickstart.md) for Operator readiness, source/converted
monitor evidence, authorization target health, application and Kubernetes
metrics, queue drain gates, no duplicate target scraping, Secret rotation, and
PVC identity preservation.

## Complexity Tracking

| Addition | Why needed | Simpler alternative rejected because |
|---|---|---|
| Operator Helm release plus VMAgent CR | Existing application monitors, ownership, and Secret authorization must be reconciled automatically | Standalone vmagent requires central duplication of every monitor and credential |
| Prometheus release required in VM mode | It currently owns the source monitor CRDs | Independent CRD ownership needs a separate adoption/upgrade migration |
| Native KSM VMServiceScrape | Converter does not preserve the required per-target body-size limit | A global 32 MiB limit weakens every target's guard |
| Protected two-layer Operator values | Raw values remain useful without allowing collection safety controls to be removed | Unrestricted raw overrides can create no scraper, duplicate scrapers, or unsafe cleanup |
| Coordinated AWS wrapper update | EKS callers need the same object type at the wrapper boundary | Wrapper-specific resources would duplicate base-module ownership |
