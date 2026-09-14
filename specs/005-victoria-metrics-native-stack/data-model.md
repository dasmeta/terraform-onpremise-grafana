# Data Model: VictoriaMetrics Native Stack

This feature is declarative infrastructure. The entities below describe the
resolved Terraform configuration and generated Kubernetes resources rather
than a persisted application database.

## MetricsStackSelection

Represents the public backend and collector decision.

| Field | Type | Rules |
|---|---|---|
| `metrics_collector` | enum | `prometheus` or `victoria_metrics` |
| `prometheus_enabled` | bool | Must be true when Prometheus is selected |
| `victoria_metrics_enabled` | bool | Must be true when VictoriaMetrics is selected |
| `prometheus_scraping_enabled` | derived bool | True only when Prometheus is selected and installed |
| `vmagent_enabled` | derived bool | True only when VictoriaMetrics is selected and installed |
| `prometheus_converter_enabled` | derived bool | True only when Prometheus and VictoriaMetrics are both installed |
| `default_datasource_uid` | derived string | Matches the selected, installed backend |

### Invariants

- Exactly one of `prometheus_scraping_enabled` and `vmagent_enabled` is true in
  every valid configuration.
- Backend installation and collector activation are separate concerns.
- VM-only is valid without a Prometheus release or Prometheus CRD.
- Switching only `metrics_collector` does not alter VictoriaMetrics storage
  identity, retention, or PVC configuration.

## SharedExporter

Represents a backend-neutral metrics producer.

| Field | Type | Rules |
|---|---|---|
| `kind` | enum | `kube_state_metrics` or `node_exporter` |
| `enabled` | bool | Controls exporter Helm release lifecycle |
| `namespace` | string | Resolved from exporter override or module namespace |
| `release_name` | string | Stable Helm instance identity |
| `fullname` | string | Stable Service/workload identity |
| `chart_version` | string | Explicitly pinned |
| `prometheus_monitor_enabled` | derived bool | Exporter enabled and Prometheus selected |
| `managed_service_scrape` | bool | Defaults true; caller can transfer VictoriaMetrics discovery ownership without disabling the exporter |
| `vm_service_scrape_enabled` | derived bool | Exporter enabled, VictoriaMetrics selected, and module-managed discovery enabled |

### Invariants

- An enabled exporter has one module-managed discovery definition unless the
  caller explicitly owns its VictoriaMetrics scrape job.
- A disabled exporter has no module-managed discovery definition.
- Disabling module-managed discovery does not disable the exporter workload or
  remove caller inline jobs.
- The Prometheus stack cannot install a bundled copy.
- Exporter Service annotations cannot activate a second annotation scrape.

## NativeDiscoveryObject

Represents a generated VictoriaMetrics discovery resource.

| Field | Type | Rules |
|---|---|---|
| `api_version` | string | `operator.victoriametrics.com/v1beta1` |
| `kind` | enum | `VMServiceScrape` or `VMNodeScrape` |
| `name` | string | Deterministic and DNS-compatible |
| `namespace` | string | Namespace where the object is owned |
| `selector` | object | Matches stable Service labels for service scrapes |
| `endpoints` | list | Named port/path, interval, auth, and relabel settings |
| `enabled` | derived bool | Requires selected VM collector and source component |

### Native node identities

| Logical name | Path | Default | Purpose |
|---|---|---:|---|
| `kubelet` | `/metrics` | enabled | kubelet/volume/health series |
| `cadvisor` | `/metrics/cadvisor` | enabled | container CPU, memory, network, filesystem |
| `resource` | `/metrics/resource` | disabled | optional pod/container resource endpoint |

Node scrapes use the mounted service-account token and intentionally skip
target certificate validation without declaring an unused CA path. They never
contain a credential value. Verified API-server and component scrapes retain
their separate CA configuration.

## VictoriaMetricsResourceRelease

Represents the module-local Helm release that owns VM custom-resource
instances.

| Field | Type | Rules |
|---|---|---|
| `name` | string | Derived from the Operator release identity |
| `namespace` | string | Same namespace as the Operator/VMAgent |
| `objects` | list(object) | Selector-resolved VM custom resources only |
| `depends_on_operator` | bool | Always true |

### Invariants

- The Operator Helm release owns official CRDs and completes first.
- The resources release owns custom-resource instances and never owns CRDs.
- No generated object has a `monitoring.coreos.com` API version in VM-only
  mode.

## ModuleOwnedIntegration

Represents Grafana, Tempo, or Loki configuration that depends on the selected
metrics backend.

| Field | Type | Rules |
|---|---|---|
| `component` | enum | `grafana`, `tempo`, or `loki` |
| `enabled` | bool | Existing component lifecycle flag |
| `monitor_requested` | bool | Existing public self-monitoring request |
| `managed_service_scrape` | bool | Defaults true for Tempo and Loki; false transfers VictoriaMetrics discovery ownership to the caller |
| `prometheus_monitor_enabled` | derived bool | Requested and Prometheus selected |
| `vm_service_scrape_enabled` | derived bool | Requested, VictoriaMetrics selected, and module-managed discovery enabled |
| `managed_remote_write_url` | nullable string | Tempo only; selector-derived when caller omits URL |

### Invariants

- A requested module-owned monitor has at most one discovery path.
- A caller-owned inline job can replace native Tempo or Loki discovery without
  disabling the component.
- VM-only suppresses module-owned Prometheus monitors and rules.
- An explicit Tempo URL is not modified.
- An omitted Tempo URL resolves to the selected backend's write endpoint.

## CollectorStatus

Non-sensitive root output used by wrappers and rollout checks.

Required status groups:

- selected collector and installed backends;
- active scraper booleans;
- converter state;
- default datasource UID;
- VictoriaMetrics query and write URLs;
- exporter install and monitor-path state;
- native node scrape state;
- module-owned native service scrape names.

The status object contains identities and booleans only. It must not expose
credentials or rendered secret-bearing scrape configuration.

## Mode matrix

| Mode | Prom release | VM release | Prom scraper | VMAgent | Converter | Prom CRs generated by module | Native VM discovery |
|---|---:|---:|---:|---:|---:|---:|---:|
| Prometheus-only | yes | no | yes | no | no | yes | no |
| VictoriaMetrics-only | no | yes | no | yes | no | no | yes |
| Dual, Prom selected | yes | yes | yes | no | yes | yes | no |
| Dual, VM selected | yes | yes | no | yes | yes | no for module-owned paths | yes |

## State transitions

1. **Prometheus-only to dual/Prometheus-selected**: install VictoriaMetrics
   storage and Operator; keep Prometheus scraping; remote-write a validation
   copy if configured by the existing contract.
2. **Dual/Prometheus-selected to dual/VM-selected**: stop Prometheus scraping,
   create VMAgent/native discovery, keep converter compatibility and both
   storage backends.
3. **Dual/VM-selected to VM-only**: remove the Prometheus Helm release, disable
   converter compatibility, retain independent exporters and VM storage.
4. **Rollback**: reinstall/select Prometheus without destroying VictoriaMetrics
   PVCs or historical data.

Prometheus CRD cleanup is not part of any automatic transition.
