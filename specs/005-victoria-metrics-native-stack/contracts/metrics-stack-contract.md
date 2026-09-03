# Contract: Selectable Standalone Metrics Stacks

## Root input contract

### Existing selector

```hcl
metrics_collector = "prometheus" # or "victoria_metrics"
```

The selected backend must have its `enabled` flag set. VictoriaMetrics no
longer requires `prometheus.enabled = true`.

### Independent node-exporter

```hcl
node_exporter = {
  enabled           = true
  namespace         = null
  create_namespace  = true
  chart_version     = "4.47.1"
  release_name      = "node-exporter"
  fullname_override = "prometheus-node-exporter"

  resources = {
    requests = {
      cpu    = "100m"
      memory = "200Mi"
    }
    limits = {
      cpu    = "200m"
      memory = "500Mi"
    }
  }

  extra_configs = {}
}
```

`enabled` controls only exporter lifecycle. The selected collector controls
whether its discovery object is a Prometheus `ServiceMonitor` or native
`VMServiceScrape`. Selector-owned values disable annotation scraping and
prevent `extra_configs` from enabling a second monitor path.

### VictoriaMetrics native node collection

The existing `victoria_metrics.agent` object gains optional fields:

```hcl
victoria_metrics = {
  agent = {
    name                    = "victoria-metrics-agent"
    replica_count           = 1
    kubelet_scrape_enabled  = true
    cadvisor_scrape_enabled = true
    resource_scrape_enabled = false
    kubelet_metrics         = [
      "container_cpu_.*",
      "container_memory_.*",
      "kube_pod_container_status_.*",
      "kube_pod_container_resource_.*",
      "container_network_.*",
      "kube_pod_resource_limit",
      "kube_pod_resource_request",
      "pod_cpu_usage_seconds_total",
      "pod_memory_usage_bytes",
      "kubelet_volume_stats.*",
      "volume_operation_total_seconds.*",
      "container_fs_.*",
    ]
    extra_scrape_configs = []
    extra_configs        = {}
  }
}
```

The node scrape flags affect only an active VMAgent. They do not change
Prometheus kubelet monitor behavior.

### Tempo remote write

```hcl
tempo = {
  metrics_generator = {
    enabled    = true
    remote_url = null
  }
}
```

- `null` means use the selected backend's write endpoint.
- A non-null URL is caller-owned and preserved exactly.

## Root validation contract

| Collector | Prom enabled | VM enabled | Result |
|---|---:|---:|---|
| `prometheus` | true | false/true | valid |
| `prometheus` | false | any | invalid |
| `victoria_metrics` | false/true | true | valid |
| `victoria_metrics` | any | false | invalid |

Every valid row resolves exactly one active scraper.

## Generated resource contract

### Prometheus selected

- kube-prometheus-stack's Prometheus server is enabled.
- bundled kube-state-metrics and node-exporter are disabled.
- enabled independent exporters create one `ServiceMonitor` each.
- kubelet/cAdvisor remain managed by kube-prometheus-stack.
- no VMAgent or module-owned native VM scrape object is generated.

### VictoriaMetrics selected

- kube-prometheus-stack's Prometheus server is disabled or absent.
- one VMAgent writes to the module-derived vminsert URL.
- enabled independent exporters create one native `VMServiceScrape` each.
- enabled native node paths create deterministic `VMNodeScrape` objects.
- requested Tempo/Loki self-monitoring creates native `VMServiceScrape`
  objects and no module-owned `ServiceMonitor`.
- every VM object is owned by a dedicated resources Helm release that depends
  on the VictoriaMetrics Operator release.

### Converter

- Prometheus absent: converter disabled and converter ownership disabled.
- Prometheus present with VictoriaMetrics installed: converter enabled for
  migration compatibility.
- Raw Operator environment and values cannot reverse this result.

## Selector-owned values

The following values are final and cannot be overridden by raw chart values:

- Prometheus server collector activation;
- bundled kube-state-metrics and node-exporter disablement;
- independent exporter monitor type and annotation scraping disablement;
- VictoriaMetrics CRD install/upgrade and cleanup policy;
- converter activation and ownership;
- VMAgent identity, replica count, remote write, inline scrape config, and
  selectors for native scrape kinds;
- module-owned Prometheus monitor suppression in VM mode;
- VictoriaMetrics cluster component Prometheus ServiceMonitor suppression in
  VM-only mode;
- selector-derived Tempo remote write when the public input is null.

Unrelated scheduling, image, labels, tolerations, resource overrides, and
chart-specific options remain caller-configurable unless they conflict with an
invariant above.

## Output contract

`metrics_collector_status` remains non-sensitive and adds:

```hcl
{
  prometheus_converter_enabled = bool
  victoria_metrics_standalone   = bool

  node_exporter_installed                  = bool
  node_exporter_prometheus_monitor_enabled = bool
  node_exporter_vm_service_scrape_enabled  = bool

  vm_node_scrapes = {
    kubelet  = bool
    cadvisor = bool
    resource = bool
  }

  vm_service_scrapes = {
    kube_state_metrics = bool
    node_exporter      = bool
    tempo              = bool
    loki               = bool
  }
}
```

Exact object names and service identities may also be exposed, but rendered
scrape YAML and credential data must not be outputs.

## Security contract

- VMNodeScrape uses service-account token and CA **file paths**, not values.
- Terraform does not read application metric tokens.
- Caller inline scrape jobs remain accepted but must reference mounted secrets
  rather than embedding credentials.
- Tests and documentation use only non-secret examples.

## Compatibility boundaries

- Existing Prometheus-only defaults remain valid.
- Both backends may remain installed for migration.
- Application-owned Prometheus monitors are not translated by Terraform.
- Additional Prometheus scrape jobs are not copied to VMAgent.
- Prometheus Alertmanager and chart-provided rules have no VM-only replacement
  in this feature.
- Old Prometheus CRDs are never automatically removed.
