# Research: Selectable Metrics Collectors with VictoriaMetrics Operator

**Feature**: `004-metrics-collector-selection`
**Date**: 2026-08-28

## Decision 1: Keep installation separate from active collection

**Decision**: Keep `prometheus.enabled` and `victoria_metrics.enabled` as
installation switches and keep `metrics_collector` as the active-scraper
selector.

**Rationale**: The migration needs both backends installed while only one
component scrapes. Prometheus can remote-write a validation copy to the existing
VictoriaMetrics cluster before VMAgent becomes active.

**Alternatives considered**:

- Reinterpret `enabled` as collection state — rejected because it cannot express
  “installed but inactive”.
- Add a converged `both` mode — rejected because two scrapers duplicate target
  load and complicate ownership and deduplication.

## Decision 2: Replace the standalone agent chart with VictoriaMetrics Operator

**Decision**: Install the official `victoria-metrics-operator` chart at version
`0.67.2` whenever VictoriaMetrics is installed. Render one `VMAgent` custom
resource through the chart's `extraObjects` only when
`metrics_collector = "victoria_metrics"`.

The root VictoriaMetrics child depends on the Prometheus and independent
kube-state-metrics modules so the Operator cannot race source monitor CRDs or a
custom exporter namespace during a fresh install.

**Rationale**: The standalone `victoria-metrics-agent` chart only consumes its
own Prometheus scrape file. VictoriaMetrics Operator reconciles Prometheus
`PodMonitor` and `ServiceMonitor` resources into VictoriaMetrics scrape
resources and generates VMAgent configuration continuously. Version `0.67.2`
contains the `0.67.1` network-policy RBAC correction and the converter startup
correction described in the official chart changelog.

**Alternatives considered**:

- Keep standalone vmagent and duplicate every monitor as a manual job — rejected
  because credentials and future monitor changes would have two owners.
- Replace the stack with `victoria-metrics-k8s-stack` — rejected because it would
  overlap the existing cluster, exporters, service names, rules, and PVCs.
- Create Deployment, RBAC, and ConfigMap resources directly — rejected because
  that duplicates operator behavior and upgrade logic.

Official references: [VictoriaMetrics Operator Prometheus integration](https://docs.victoriametrics.com/operator/integrations/prometheus/),
[operator chart changelog](https://docs.victoriametrics.com/helm/victoria-metrics-operator/changelog/).

## Decision 3: Keep Prometheus monitoring CRDs owned by kube-prometheus-stack

**Decision**: Require both `prometheus.enabled = true` and
`victoria_metrics.enabled = true` when VictoriaMetrics is selected in this
operator-conversion rollout.

**Rationale**: VictoriaMetrics Operator converts Prometheus monitor objects but
does not install the `monitoring.coreos.com` CRDs that define them. The current
kube-prometheus-stack release remains their owner even when its Prometheus
server is disabled. Allowing `prometheus.enabled = false` would make existing
application chart installs dependent on CRDs with no declared lifecycle owner.

**Alternatives considered**:

- Install Prometheus Operator CRDs in the VictoriaMetrics child module — rejected
  for this feature because ownership transfer, adoption, and upgrades require a
  separate migration.
- Leave Victoria-only mode valid — rejected because it can silently remove the
  APIs required by source monitors.

## Decision 4: Preserve Secret-backed monitor authorization at runtime

**Decision**: Enable Prometheus conversion and converter owner references. Do
not copy application tokens into Terraform variables, Helm values, examples, or
state.

**Rationale**: The converter preserves the endpoint authorization type and
`SecretKeySelector`. The operator reads the source Secret in the monitor's
namespace and resolves it into the generated VMAgent configuration Secret at
runtime. This keeps Terraform outside the credential path. Runtime conversion
needs source-Secret reads, while the pinned chart's generated ClusterRole grants
broader cluster-wide wildcard verbs on `secrets` and `secrets/finalizers`.
Restrict and audit the Operator service account plus both source and generated
Secrets. Narrower custom RBAC is deferred to a separate hardening change.

**Alternatives considered**:

- Mount a central copied token into a standalone agent — rejected because it
  creates duplicate Secret ownership and rotation work.
- Put the token in `agent.extra_scrape_configs` — rejected because inline scrape
  configuration is visible in Terraform and Helm release data.

Official references: [operator conversion](https://docs.victoriametrics.com/operator/integrations/prometheus/),
[operator security](https://docs.victoriametrics.com/operator/security/).

## Decision 5: Make selector-owned Operator and VMAgent fields authoritative

**Decision**: Apply `operator.extra_configs` as the first Helm values document
and selector-owned chart values as the last document. Merge
`agent.extra_configs` into the VMAgent spec while replacing protected fields
last.

**Protected Operator values**:

- `operator.disable_prometheus_converter = false`
- `operator.enable_converter_ownership = true`
- top-level `watchNamespaces = []`
- top-level `extraArgs["controller.disableReconcileFor"] = []`, while preserving
  unrelated caller arguments
- filtered top-level `env` without `WATCH_NAMESPACE` or
  `VM_ENABLEDPROMETHEUSCONVERTER*`, plus `envFrom = []`; unrelated explicit env
  entries remain supported
- `rbac.create = true`
- `crds.enabled = true`
- `crds.cleanup.enabled = false`
- generated `extraObjects`

**Protected VMAgent values**:

- resource activation and metadata name
- `spec.selectAllByDefault = true`
- absence of raw `podScrapeSelector`, `podScrapeNamespaceSelector`,
  `serviceScrapeSelector`, and `serviceScrapeNamespaceSelector`
- `spec.remoteWrite`
- `spec.replicaCount`
- `spec.inlineScrapeConfig`
- the top-level `resources` and `extraArgs` maps, which are rebuilt from
  explicit nested merges before being placed in the protected final spec

Operational resource leaf defaults and
`extraArgs["remoteWrite.queues"] = "16"` remain overrideable through their
documented nested `agent.extra_configs` maps; unspecified siblings retain
defaults. Caller jobs from `agent.extra_scrape_configs` are YAML-encoded into
`spec.inlineScrapeConfig`; they must not contain credentials.

Official references: [Operator chart changelog](https://github.com/VictoriaMetrics/helm-charts/blob/master/charts/victoria-metrics-operator/CHANGELOG.md),
[VMAgent resource and inline scrape configuration](https://docs.victoriametrics.com/operator/resources/vmagent/).

## Decision 6: Use a native VMServiceScrape for kube-state-metrics

**Decision**: In Prometheus mode, retain the standalone kube-state-metrics
`ServiceMonitor`. In VictoriaMetrics mode, disable it and render one native
`VMServiceScrape` with endpoint-level `max_scrape_size = "32MiB"` and a
`-victoria-metrics` name suffix. The distinct object name avoids a Helm
ownership race with the same-name object converted from the Prometheus
`ServiceMonitor` while that source is being removed.

**Rationale**: The exporter has returned approximately 20 MB, above vmagent's
16 MiB default. The operator converter does not translate Prometheus
`bodySizeLimit` to VictoriaMetrics `max_scrape_size`, so this one exporter needs
a native VictoriaMetrics object. A per-endpoint limit avoids weakening the
global guard.

The native object uses the resolved exporter namespace, Service selector labels,
port `http`, `honorLabels = true`, and the 32 MiB limit. A caller-provided
inline job named `kube-state-metrics` suppresses the native object during
migration; the caller owns that job's size limit.

Official references: [VMServiceScrape](https://docs.victoriametrics.com/operator/resources/vmservicescrape/),
[vmagent scrape-size flag](https://docs.victoriametrics.com/victoriametrics/vmagent/).

## Decision 7: Preserve VictoriaMetrics storage and use a guarded two-apply handoff

**Decision**: Keep the existing `victoria-metrics-cluster` release, service
names, retention, vmstorage replicas, and PVC identities unchanged. Upgrade to
the operator in Prometheus mode first, then switch the selector in a second
apply.

**Rationale**: The first apply proves conversion while Prometheus still
collects. The second apply creates VMAgent and disables the Prometheus server.
Separate Helm releases cannot switch atomically, so a bounded overlap or gap is
possible during convergence.

Before switching, require
`prometheus_remote_storage_samples_pending == 0` for two scrape intervals and no
increase in failed/retried remote-write counters. Before rollback, require
`vmagent_remotewrite_pending_data_bytes == 0` and clear remote-write errors,
because the planned VMAgent queue remains ephemeral unless explicitly changed
through `agent.extra_configs`.

## Decision 8: Mirror the revised contract in the AWS wrapper

**Decision**: Update `terraform-aws-grafanav12` to expose and forward
`victoria_metrics.operator` and the revised `victoria_metrics.agent` object
without implementing any operator resources itself.

**Rationale**: The base module remains the single owner of Kubernetes and Helm
behavior. Wrapper examples and validation must use the same input shape so EKS
consumers can select VictoriaMetrics without a local schema mismatch.

## Decision 9: Bootstrap Operator CRDs through Helm's plain CRD path

**Decision**: Protect `crds.enabled = true`, `crds.plain = true`, and
`crds.upgrade.enabled = true` in the final Operator values document.

**Rationale**: In chart `0.67.2`, `crds.plain = false` renders CRDs as ordinary
templates while the module renders `VMAgent` and `VMServiceScrape` through the
same release's `extraObjects`. On a fresh cluster Helm attempts to build REST
mappings for those custom resources before their API kinds exist. With
`crds.plain = true`, the chart's bundled CRD subchart places definitions under
Helm's `crds/` mechanism, which is installed before regular manifests. Because
Helm does not normally upgrade plain CRDs, the chart-provided pre-upgrade job is
also enabled to server-side apply the pinned CRD payload on later upgrades.

**Alternatives considered**:

- Retry the same release after a failed apply — rejected because first install
  must be deterministic and must not require a partial bootstrap.
- Disable OpenAPI validation — rejected because REST mapping still requires the
  CRD kind to exist.
- Add a separate raw-object Helm release — rejected as unnecessary once the
  pinned chart's supported plain-CRD and upgrade-job path provides the required
  ordering.

Official references: [Operator chart values](https://github.com/VictoriaMetrics/helm-charts/blob/master/charts/victoria-metrics-operator/values.yaml),
[Operator chart changelog](https://github.com/VictoriaMetrics/helm-charts/blob/master/charts/victoria-metrics-operator/CHANGELOG.md).
