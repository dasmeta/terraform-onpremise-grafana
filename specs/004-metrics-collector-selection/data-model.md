# Data Model: Selectable Metrics Collectors with Operator Conversion

**Feature**: `004-metrics-collector-selection`

## Entities

### MetricsCollectorSelection

| Field | Type | Description | Validation |
|---|---|---|---|
| `metrics_collector` | string | Active scraper and default metrics datasource | `prometheus` or `victoria_metrics`; defaults to `prometheus` |
| `prometheus.enabled` | bool | Installs kube-prometheus-stack and owns Prometheus monitoring CRDs | Must be true for Prometheus mode and for the current VictoriaMetrics conversion mode |
| `victoria_metrics.enabled` | bool | Installs the existing VM cluster and VM Operator | Must be true for VictoriaMetrics mode |

### VictoriaMetricsOperatorConfig

| Field | Type | Default | Validation/ownership |
|---|---|---|---|
| `chart_version` | string | `0.67.2` | Tested official chart version |
| `release_name` | string | `victoria-metrics-operator` | Helm release name |
| `extra_configs` | any/map | `{}` | Applied before protected conversion, RBAC, CRD, and `extraObjects` values |

### VictoriaMetricsAgentConfig

| Field | Type | Default | Validation/ownership |
|---|---|---|---|
| `name` | string | `victoria-metrics-agent` | Valid Kubernetes DNS subdomain/resource name |
| `replica_count` | number | `1` | Positive integer |
| `extra_scrape_configs` | list-like value | `[]` | YAML-encoded into `inlineScrapeConfig`; no credentials |
| `extra_configs` | any/map | `{}` | VMAgent spec overrides except selector-owned fields |

Generated VMAgent defaults include resource requests of `1` CPU and `512Mi`,
limits of `2` CPU and `1Gi`, and
`extraArgs["remoteWrite.queues"] = "16"`. Partial resource and extra-argument
overrides retain unspecified defaults.

### OperatorManagedObject

| Kind | Activation | Purpose |
|---|---|---|
| `VMAgent` | VictoriaMetrics selected | Selects scrape CRs across namespaces and writes to existing vminsert |
| `VMServiceScrape` for kube-state-metrics | VictoriaMetrics selected, exporter enabled, no caller transition job | Uses `<Service fullname>-victoria-metrics` to avoid converter ownership collision and preserves the exporter-specific 32 MiB scrape limit |

### ApplicationMonitor

| Field group | Owner | Runtime behavior |
|---|---|---|
| `PodMonitor`/`ServiceMonitor` selectors, path, port, interval | Application chart | Converted by VictoriaMetrics Operator |
| Authorization type and Secret selector | Application chart | Preserved by conversion |
| Secret value | Application namespace | Read by the Operator and written to generated VMAgent config Secret; never supplied to Terraform |

Runtime conversion needs source-Secret reads. The pinned chart-owned
ClusterRole grants broader cluster-wide wildcard verbs on `secrets` and
`secrets/finalizers`; the Operator service account and both source/generated
Secrets therefore require restricted access and auditing.

### KubeStateMetricsIntegration

| Field | Description |
|---|---|
| resolved namespace | `kube_state_metrics.namespace`, then Prometheus namespace, then root namespace |
| resolved fullname | explicit fullname override or `<prometheus.release_name>-kube-state-metrics` |
| Service selector | `app.kubernetes.io/name = kube-state-metrics`, `app.kubernetes.io/instance = <standalone release_name>` |
| endpoint | port `http`, `honorLabels = true`, `max_scrape_size = "32MiB"` in VM mode |

### MetricsBackendStorage

The existing VictoriaMetrics cluster release, vminsert/vmselect service DNS,
retention period, vmstorage replica count, and PVC settings are independent from
the collector selector and Operator/VMAgent lifecycle.

Raw cluster values may override non-endpoint settings. The module applies a
final contract for release-derived, 63-character-safe vminsert/vmselect Service
identity, enablement, HTTP listen ports, and Service ports so the derived
VMAgent remote-write URL and Grafana query URL cannot drift from the rendered
Services without changing vmstorage naming.

## Relationships

```text
PodMonitor / ServiceMonitor
          -> VictoriaMetrics Operator converter
          -> VMPodScrape / VMServiceScrape
          -> selected operator-managed VMAgent
          -> existing vminsert
          -> existing vmstorage PVCs
```

- Prometheus mode creates no VMAgent; converted objects may exist but are inert.
- VictoriaMetrics mode creates one VMAgent and disables the Prometheus server.
- The native kube-state-metrics VMServiceScrape bypasses conversion only because
  the required response-size limit is not converted.
- Grafana keeps datasources for every installed backend and defaults to the
  selected collector.
- The AWS wrapper forwards the whole revised nested object to the base module.

## State transitions

```text
Both installed, Prometheus selected
  -> operator installed and monitor conversion verified
  -> Prometheus remote-write queue drained
  -> selector changed to victoria_metrics
  -> VMAgent created; Prometheus server disabled
  -> VM storage/PVCs unchanged

VictoriaMetrics selected
  -> VMAgent pending queue drained
  -> selector changed to prometheus
  -> VMAgent removed; Prometheus server restored
  -> VM storage/PVCs unchanged
```

The exactly-one-scraper invariant applies after convergence. A selector apply
can have a bounded overlap or gap because two Helm releases change independently.

## Validation rules

1. `metrics_collector` is `prometheus` or `victoria_metrics`.
2. Prometheus mode requires `prometheus.enabled = true`.
3. VictoriaMetrics mode requires both backend releases enabled until Prometheus
   monitor CRDs have an independent owner.
4. `victoria_metrics.agent.name` is a label-separated Kubernetes DNS subdomain;
   empty labels and labels starting/ending with `-` are invalid.
5. `victoria_metrics.agent.replica_count` is a positive integer.
6. Selector-owned Operator values and generated objects win over raw chart
   overrides, including attempted `env`/`envFrom`, namespace-watch, and
   `extraArgs["controller.disableReconcileFor"]` converter bypasses.
7. Selector-owned VMAgent name, activation, selectors, replica count,
   inline scrape config, and remote-write destination win over raw spec values;
   explicit Pod/Service scrape and namespace selectors are absent.
8. Changing the selector does not change VM cluster storage identities.
9. The VictoriaMetrics child waits for Prometheus CRD ownership and independent
   kube-state-metrics namespace creation on fresh installs.
