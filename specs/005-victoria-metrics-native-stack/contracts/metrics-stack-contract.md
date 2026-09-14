# Contract: Selectable Standalone Metrics Stacks

## Root input contract

### Existing selector

```hcl
metrics_collector = "prometheus" # or "victoria_metrics"
```

The selected backend must have its `enabled` flag set. VictoriaMetrics no
longer requires `prometheus.enabled = true`, but selecting it as the collector
requires its Operator gate.

### Explicit VictoriaMetrics Operator gate

```hcl
victoria_metrics = {
  enabled = true
  operator = {
    enabled = false
  }
}
```

`victoria_metrics.enabled` installs the VictoriaMetrics Cluster only.
`victoria_metrics.operator.enabled` defaults to `false` and independently gates
both the official Operator release (including its CRDs and cluster-wide RBAC)
and the dependent module-local custom-resource release. This default preserves
storage-only consumers during upgrade.

With Prometheus selected, the Operator may remain disabled while Prometheus
remote-writes to the VictoriaMetrics cluster. Set the Operator gate to `true`
explicitly before using monitor conversion or selecting VictoriaMetrics as the
active collector.

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
    managed_service_scrapes = {
      kube_state_metrics = true
      node_exporter      = true
      tempo              = true
      loki               = true
    }
    kubelet_metrics         = [
      "container_cpu_.*",
      "container_memory_.*",
      "container_network_.*",
      "pod_cpu_usage_seconds_total",
      "pod_memory_working_set_bytes",
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
Prometheus kubelet monitor behavior. The list is a union: known patterns are
routed only to the kubelet, cAdvisor, or resource endpoint that exposes them;
unknown caller patterns are retained on every enabled node endpoint. Metrics
owned by kube-state-metrics or kube-scheduler are excluded from VMNodeScrapes.

Each `managed_service_scrapes` field is optional and defaults to `true`.
Setting one to `false` suppresses only that module-owned VictoriaMetrics
`VMServiceScrape`; it does not alter workload lifecycle, Prometheus discovery,
or `extra_scrape_configs`. An exact caller job named `kube-state-metrics`
continues to suppress native KSM discovery for migration compatibility.

### VictoriaMetrics native Kubernetes component collection

The existing `victoria_metrics.agent` object also accepts one grouped optional
configuration:

```hcl
victoria_metrics = {
  agent = {
    kubernetes_component_scrapes = {
      namespace            = "kube-system"
      api_server_namespace = "default"
      api_server            = false
      core_dns              = true
      kube_proxy            = true
      controller_manager    = true
      scheduler             = true
      etcd                  = true
      controller_manager_tls = {
        ca_file              = "/etc/vmagent/controller-manager/ca.crt"
        server_name          = "kube-controller-manager.internal"
        insecure_skip_verify = false
      }
      scheduler_tls = {
        ca_file              = "/etc/vmagent/scheduler/ca.crt"
        server_name          = "kube-scheduler.internal"
        insecure_skip_verify = false
      }
    }
  }
}
```

All component fields are optional. CoreDNS, kube-proxy, and etcd are enabled by
default. Controller-manager and scheduler require explicit TLS configuration
before enabling them. `api_server = false` preserves this module's existing
explicit API server default.
The TLS objects let self-managed clusters point VMAgent at a mounted
component-specific CA and matching SAN. Certificate verification is enabled by
default; bypassing it requires explicit `insecure_skip_verify = true`.

The component booleans in module outputs describe rendered discovery
configuration only. Runtime target health is intentionally not inferred from a
Terraform plan because managed Kubernetes control-plane endpoints may be absent.

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

| Collector | Prom enabled | VM enabled | VM Operator enabled | Result |
|---|---:|---:|---:|---|
| `prometheus` | true | false/true | false/true | valid |
| `prometheus` | false | any | any | invalid |
| `victoria_metrics` | false/true | true | true | valid |
| `victoria_metrics` | any | true | false | invalid |
| `victoria_metrics` | any | false | any | invalid |

Every valid row resolves exactly one active scraper.

## Generated resource contract

### Prometheus selected

- kube-prometheus-stack's Prometheus server is enabled.
- VictoriaMetrics may be a cluster-only remote-write/query backend when its
  Operator gate is disabled.
- bundled kube-state-metrics and node-exporter are disabled.
- enabled independent exporters create one `ServiceMonitor` each.
- kubelet/cAdvisor remain managed by kube-prometheus-stack.
- no VMAgent or module-owned native VM scrape object is generated.

### VictoriaMetrics selected

- kube-prometheus-stack's Prometheus server is disabled or absent.
- one VMAgent writes to the module-derived vminsert URL.
- enabled independent exporters create one native `VMServiceScrape` each.
- a caller-disabled managed service scrape creates no native object while its
  source workload and caller inline job remain configured.
- enabled native node paths create deterministic `VMNodeScrape` objects.
- requested Tempo/Loki self-monitoring creates native `VMServiceScrape`
  objects and no module-owned `ServiceMonitor`.
- when Prometheus is absent, enabled Kubernetes components create native
  Service/VMServiceScrape pairs; API server discovery reuses the existing
  Kubernetes Service and creates only a VMServiceScrape.
- when Prometheus remains installed for migration, no native Kubernetes
  component pair is generated because the converter consumes the chart-owned
  ServiceMonitors.
- every VM object is owned by a dedicated resources Helm release that depends
  on the VictoriaMetrics Operator release.

### Converter

- Prometheus absent: converter disabled and converter ownership disabled.
- Prometheus present with the VictoriaMetrics cluster and Operator installed:
  converter enabled for migration compatibility.
- Operator disabled: converter, VMAgent, generated VM resources, and their
  resources Helm release are absent.
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
  victoria_metrics_operator_installed = bool
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
    api_server         = bool
    core_dns           = bool
    kube_proxy         = bool
    controller_manager = bool
    scheduler          = bool
    etcd               = bool
  }
}
```

Exact object names and service identities may also be exposed, but rendered
scrape YAML and credential data must not be outputs.

The child `operator_release` and `resources_release` outputs are `null`, and
`resource_objects` is empty, while `operator.enabled = false`.

## Security contract

- VMNodeScrape uses the mounted service-account token file path, intentionally
  skips kubelet certificate verification, and omits the unused CA file path.
- Terraform does not read application metric tokens.
- Caller inline scrape jobs remain accepted but must reference mounted secrets
  rather than embedding credentials.
- Tests and documentation use only non-secret examples.

## In-place migration effects

The module's supported migration is a sequence of complete root-module applies;
targeted, split, or otherwise partial applies are outside the contract because
they can leave Helm ownership handoffs incomplete.

- kube-state-metrics keeps the default resource fullname
  `prometheus-kube-state-metrics`, but ownership moves from Helm release
  `prometheus` to `kube-state-metrics`. Root dependencies order removal of the
  bundled subchart before creation by the standalone release.
- node-exporter changes from bundled fullname
  `prometheus-prometheus-node-exporter` to standalone fullname
  `prometheus-node-exporter`; a bounded scrape gap is permitted during
  replacement.
- with both releases installed, selecting `victoria_metrics` sets the
  kube-prometheus-stack Prometheus server to disabled. The Helm release remains,
  but the `Prometheus` custom resource and Operator-generated StatefulSet are
  removed. Existing Prometheus PVCs are expected to remain under the current
  storage contract, but must be inventoried before and verified after the
  apply. Prometheus history is inaccessible until the server is recreated and
  the same claims are reattached.

An interrupted kube-state-metrics ownership transfer is recovered by first
rerunning the complete root apply. Manual deletion is permitted only for the
exact stale object after its Helm release annotations prove that the old
release owns it and that release no longer renders it. Bulk deletion of
exporter resources, PVCs, or CRDs is never part of this recovery.

## Compatibility boundaries

- Existing Prometheus-only defaults remain valid.
- Both backends may remain installed for migration.
- Application-owned Prometheus monitors are not translated by Terraform.
- Additional Prometheus scrape jobs are not copied to VMAgent.
- Prometheus Alertmanager and chart-provided rules have no VM-only replacement
  in this feature.
- Old Prometheus CRDs are never automatically removed.
