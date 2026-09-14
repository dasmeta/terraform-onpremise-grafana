# Metrics Collector and Operator Contract

**Feature**: `004-metrics-collector-selection`
**Base module**: `terraform-onpremise-grafana`
**Wrapper**: `terraform-aws-grafanav12`

## Root inputs

| Input | Type | Default | Contract |
|---|---|---|---|
| `metrics_collector` | string | `prometheus` | Active scraper; only `prometheus` and `victoria_metrics` are valid |
| `prometheus.enabled` | bool | `true` | Installs kube-prometheus-stack and owns Prometheus monitor CRDs |
| `victoria_metrics.enabled` | bool | `false` | Installs the existing VM cluster and VictoriaMetrics Operator |
| `kube_state_metrics` | object | `{}` | Independent exporter shared by either collector |

The revised VictoriaMetrics object is:

```hcl
victoria_metrics = {
  enabled = true

  operator = {
    enabled       = true
    chart_version = "0.67.2"
    release_name  = "victoria-metrics-operator"
    extra_configs = {}
  }

  agent = {
    name                 = "victoria-metrics-agent"
    replica_count        = 1
    extra_scrape_configs = []
    extra_configs        = {}
  }
}
```

`agent.name` is the `VMAgent` Kubernetes resource name, not a Helm release
name. The former standalone fields `agent.chart_version` and
`agent.release_name` are replaced by `operator.chart_version`,
`operator.release_name`, and `agent.name`.

## Validation contract

| Prometheus installed | VictoriaMetrics installed | Selector | Valid | Reason |
|---:|---:|---|---:|---|
| yes | no | `prometheus` | yes | Backward-compatible Prometheus-only mode |
| yes | yes | `prometheus` | yes | Prometheus collects and remote-writes a validation copy |
| yes | yes | `victoria_metrics` | yes | VMAgent collects; kube-prometheus-stack retains monitor CRD ownership |
| no | yes | `victoria_metrics` | no | Prometheus monitor CRDs do not yet have independent ownership |
| no | any | `prometheus` | no | Selected collector is not installed |
| any | no | `victoria_metrics` | no | Selected backend is not installed |

`victoria_metrics.agent.replica_count` must be an integer greater than zero.
`victoria_metrics.agent.name` must be a valid Kubernetes DNS subdomain name.

## Deployment behavior

| Selector | Prometheus server | Operator | VMAgent | VM write path | Default datasource |
|---|---:|---:|---:|---|---|
| `prometheus` with VM disabled | active | absent | absent | none | Prometheus |
| `prometheus` with VM enabled | active | installed | absent | Prometheus remote write → vminsert | Prometheus |
| `victoria_metrics` | disabled | installed | one CR | VMAgent → vminsert | VictoriaMetrics |

The module guarantees one scraper after Terraform/Helm convergence. Because the
Prometheus and Operator charts are separate releases, selector apply and rollback
may include a bounded overlap or collection gap.

## Operator Helm contract

The VictoriaMetrics child module installs:

- unchanged `victoria-metrics-cluster` release;
- `victoria-metrics-operator` chart version `0.67.2`;
- no standalone `victoria-metrics-agent` Helm release.

At the root, this child depends on both the Prometheus and independent
kube-state-metrics modules. This orders Operator startup after Prometheus monitor
CRDs and any custom exporter namespace exist.

`operator.extra_configs` is the first values document. A final generated values
document owns:

```yaml
operator:
  disable_prometheus_converter: false
  enable_converter_ownership: true
watchNamespaces: []
extraArgs:
  controller.disableReconcileFor: []
env: <caller env excluding WATCH_NAMESPACE and VM_ENABLEDPROMETHEUSCONVERTER*>
envFrom: []
rbac:
  create: true
crds:
  enabled: true
  plain: true
  cleanup:
    enabled: false
  upgrade:
    enabled: true
extraObjects: <module-generated objects only>
```

Callers cannot inject or replace `extraObjects` through
`operator.extra_configs`. They also cannot disable Prometheus monitor
reconciliation through `extraArgs.controller.disableReconcileFor`; the module
sets that key to an empty list while retaining unrelated caller arguments.
Caller env entries that can narrow watch scope or disable conversion are
filtered, and `envFrom` is empty because referenced values cannot be inspected;
unrelated explicit env entries remain.

`crds.plain = true` is required for first-install ordering: Helm installs the
chart's bundled CRDs before it REST-maps `extraObjects`. The chart's CRD upgrade
hook remains enabled because Helm does not upgrade plain CRDs by itself. Caller
settings may tune non-protected upgrade-job fields, but cannot disable either
the plain bootstrap path or the upgrade job.

## VMAgent object contract

When VictoriaMetrics is selected, generated `extraObjects` contains exactly one
`VMAgent` and one module-owned kube-state-metrics `VMServiceScrape`. The
`VMAgent` object is:

```yaml
apiVersion: operator.victoriametrics.com/v1beta1
kind: VMAgent
metadata:
  name: <agent.name>
  namespace: <resolved VictoriaMetrics namespace>
spec:
  replicaCount: <agent.replica_count>
  selectAllByDefault: true
  remoteWrite:
    - url: <derived vminsert write URL>
  inlineScrapeConfig: <yamlencoded agent.extra_scrape_configs>
```

Generated resource defaults are requests `1 CPU/512Mi`, limits `2 CPU/1Gi`,
and `extraArgs.remoteWrite.queues = "16"`. Non-protected
`agent.extra_configs` may partially override these leaf defaults. The module
rebuilds the top-level `resources` and `extraArgs` maps from explicit nested
merges so unspecified siblings survive. Raw values cannot override activation,
metadata name, `replicaCount`, `selectAllByDefault`, Pod/Service scrape or
namespace selectors, `remoteWrite`, or `inlineScrapeConfig`.

Inline scrape configuration is for exceptional targets without monitor CRs.
Tokens, passwords, and other credentials must not be placed there.

## Backend endpoint contract

`victoria_metrics.extra_configs` is applied before a final module-owned cluster
values document. The final document keeps vminsert enabled on HTTP/Service port
`8480`, vmselect enabled on HTTP/Service port `8481`, and both Services on
explicit release-derived, 63-character-safe full names. Callers may
override non-endpoint cluster settings, but cannot make the VMAgent remote-write
or Grafana query URL diverge from the rendered Services.

When the selector enables Prometheus validation remote-write, the module merges
at `prometheus.prometheusSpec` depth. Only `remoteWrite` is selector-owned;
caller selectors, affinity, storage, and other sibling fields survive. The
Prometheus monitor CRD value is protected as enabled while this release owns
the source CRDs.

## Grafana ServiceMonitor precedence

The root module passes an explicit collector-resolved boolean to the Grafana
child, so the selected collector owns the root deployment's ServiceMonitor
state. For direct child-module consumers, `prometheus_monitor_enabled = null`
preserves `extra_configs.serviceMonitor.enabled`; if neither input requests a
value, the child defaults the effective state to `false`.

The precedence is therefore explicit `prometheus_monitor_enabled`, then
`extra_configs.serviceMonitor.enabled`, then `false`.

## Loki monitoring precedence

The root and Loki child resolve `monitoring.serviceMonitor.enabled` and
`monitoring.rules.enabled` from one common merged view. Raw
`extra_configs.monitoring` has the same precedence it has in the Helm values
list and overrides typed `loki.monitoring`; an explicit selector-owned child
input remains authoritative over both.

For direct Loki child-module consumers, nullable
`prometheus_monitor_enabled` and `prometheus_rules_enabled` preserve that
merged caller configuration. If omitted everywhere, the typed ServiceMonitor
default remains `true` and the rules fallback remains `false`.

The precedence is therefore an explicit selector input, then
`extra_configs.monitoring`, then typed `loki.monitoring`, then the existing
per-setting fallback.

## Monitor conversion and Secret contract

Application charts continue to own `PodMonitor`/`ServiceMonitor` resources and
their endpoint Secret references. The module enables converter ownership so a
converted object follows the source object's lifecycle.

The Operator preserves authorization type and Secret key selectors, reads the
source Secret at runtime, and writes the resolved credential into its generated
VMAgent configuration Secret. Terraform does not read or copy that value.
Runtime conversion needs source-Secret reads, but the pinned chart-owned
ClusterRole grants cluster-wide wildcard verbs on `secrets` and
`secrets/finalizers`. Restrict and audit the Operator service account plus
access to source and generated Secrets. Narrower custom RBAC is outside this
rollout.

## kube-state-metrics contract

The Prometheus chart never owns kube-state-metrics. The independent exporter
defaults to chart `7.8.1`, Helm release `kube-state-metrics`, Service fullname
`prometheus-kube-state-metrics`, native scrape name
`prometheus-kube-state-metrics-victoria-metrics`, and namespace `monitoring`.
The distinct native name avoids a Helm ownership collision with the transient
same-name object converted from the Prometheus `ServiceMonitor`.

| Selector | Standalone ServiceMonitor | Native VMServiceScrape |
|---|---:|---:|
| `prometheus` | enabled with `release = <prometheus release>`, port `http`, `honorLabels = true`, drop `^go_.*` | absent |
| `victoria_metrics` | disabled | enabled with resolved namespace/selectors, port `http`, `honorLabels = true`, drop `^go_.*`, `max_scrape_size = "32MiB"` |

Both module-owned paths apply the metric-name drop before ingestion. The
disabled bundled kube-state-metrics dependency has no residual values block in
the Prometheus chart template.

The native object's Service selector is:

```yaml
app.kubernetes.io/name: kube-state-metrics
app.kubernetes.io/instance: <standalone kube-state-metrics release_name>
```

Its `namespaceSelector.matchNames` contains the resolved exporter namespace.
If a caller job named `kube-state-metrics` exists in
`agent.extra_scrape_configs`, the module retains that job and suppresses the
native object; the caller owns the custom job's scrape-size limit.

## Derived endpoints and persistence

For cluster release `R` in namespace `N`:

- write: `http://R-victoria-metrics-cluster-vminsert.N.svc.cluster.local:8480/insert/0/prometheus/api/v1/write`
- query: `http://R-victoria-metrics-cluster-vmselect.N.svc.cluster.local:8481/select/0/prometheus`

Changing `metrics_collector` does not change the VictoriaMetrics cluster release
name, retention, vmstorage replicas, or PVC settings. Existing samples remain
queryable within retention.

## Outputs

| Output | Description |
|---|---|
| `metrics_collector` | Resolved selector with backend/CRD ownership preconditions |
| `metrics_collector_status` | Installation flags, active scraper flags, Operator/VMAgent state, KSM scrape state, write URL, and default datasource UID |
| child `operator_release` | Filtered name, namespace, chart, and version only; never `helm_release.metadata` or rendered values |

## AWS wrapper parity

`terraform-aws-grafanav12` exposes the same nested `operator` and `agent`
shape and forwards `victoria_metrics = var.victoria_metrics` to the base module.
It does not create Operator, VMAgent, scrape CR, or Secret resources itself.
