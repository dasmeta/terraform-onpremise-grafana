# victoria-metrics

This child module always installs the `victoria-metrics-cluster` storage/query
backend. `operator_enabled = true` separately installs the VictoriaMetrics
Operator chart `0.67.2`, its official CRDs/RBAC, and the dependent custom-
resource release; the gate defaults to `false`. This allows cluster-only
remote-write/query usage without introducing a cluster-wide controller. The
root creates one Operator-managed `VMAgent` custom resource only when
`metrics_collector = "victoria_metrics"`; `agent.name` is its Kubernetes
resource name and `agent.replica_count` controls replicas. The VMAgent writes
to the derived vminsert service and does not own vmstorage PVCs. There is no
standalone agent Helm release.

`agent_enabled = true` requires `operator_enabled = true`. The Operator Helm
release owns only the controller and official CRDs. A second
module-local Helm release depends on it and owns all generated custom-resource
instances. This makes a clean VictoriaMetrics-only install valid without
Prometheus Operator CRDs. The Prometheus monitor converter is enabled only
when both backends are installed.

In dual-backend migration mode the Operator can convert application-owned
`PodMonitor` and `ServiceMonitor` resources, including their authorization
Secret selectors, into VMAgent configuration. Conversion is effective only
while the Operator is enabled. In VM-only mode applications
must provide native `VMPodScrape`/`VMServiceScrape` resources. Terraform never
reads Secret values. Inline
`agent_extra_scrape_configs` is only for exceptional unauthenticated targets
without monitor CRs and must contain no credentials. Direct child-module
callers that replace a generated service scrape set the corresponding
`agent_kube_state_metrics_enabled`, `agent_node_exporter_enabled`,
`agent_tempo_enabled`, or `agent_loki_enabled` input to `false`. Root-module
callers use `victoria_metrics.agent.managed_service_scrapes` for the same
explicit ownership decision. Arbitrary `job_name` values are not used to infer
targets; the existing exact `kube-state-metrics` transition job remains the
only backward-compatible automatic suppression.

The module protects Operator conversion ownership, cluster-wide monitor
discovery, VMAgent identity/activation, remote-write destination, and scrape
selector fields after caller values. VMAgent always uses
`selectAllByDefault = true` for cluster-wide native monitor discovery. The
module filters `WATCH_NAMESPACE` and `VM_ENABLEDPROMETHEUSCONVERTER*`, forces
`envFrom = []`, and clears `controller.disableReconcileFor`; unrelated env and
extra arguments remain supported. Partial VMAgent resources and `extraArgs`
overrides retain unspecified defaults.

For a deterministic first install, the module protects `crds.enabled = true`
and `crds.plain = true`, keeps the chart-provided CRD upgrade hook enabled, and
keeps CRD cleanup disabled. The dependent resources release creates VMAgent
and native scrape instances only after the Operator/CRD release succeeds.

The pinned chart's chart-owned ClusterRole grants cluster-wide wildcard verbs
on `secrets` and `secrets/finalizers` for runtime conversion. Restrict and
audit the Operator service account and both source and generated Secrets;
narrower custom RBAC is separate hardening work.

For kube-state-metrics, the independent release is shared by both collectors.
Prometheus mode uses exactly one `ServiceMonitor`; VictoriaMetrics mode uses
exactly one native `VMServiceScrape` on port `http`, with `honorLabels = true`
and `max_scrape_size = "32MiB"`. Its name adds `-victoria-metrics` to the
Service fullname so it cannot collide with the Operator-converted
`ServiceMonitor` during handoff. A caller inline job named exactly
`kube-state-metrics` suppresses the native object and remains caller-owned.

The independent node-exporter follows the same mutually exclusive monitor
contract. Native `VMNodeScrape` objects collect kubelet `/metrics` and
`/metrics/cadvisor` by default with the mounted service-account token. They
intentionally skip kubelet target certificate validation and omit the unused
CA path. The `/metrics/resource` path is opt-in. Known
`agent_kubelet_metrics` patterns are routed only to the endpoint that exposes
them; unknown caller patterns remain enabled on every selected node endpoint.
KSM/scheduler-only patterns are not added to node scrapes, and KSM metrics
continue through their separate `VMServiceScrape`. Tempo and Loki
self-monitoring are also rendered as native `VMServiceScrape` objects when
VictoriaMetrics is selected. These four service scrape objects can be disabled
independently from their workloads when caller-owned inline jobs replace them.

When `agent_standalone = true`, the module also owns Kubernetes component
discovery that kube-prometheus-stack would otherwise create. Safe defaults
render headless Service/VMServiceScrape pairs in `kube-system` for CoreDNS
(9153), kube-proxy (10249), and etcd (2381). Controller-manager (10257/HTTPS)
and kube-scheduler (10259/HTTPS) are supported but disabled until their TLS
settings are supplied explicitly. `agent_kubernetes_component_scrapes.namespace`
and each component flag can override that behavior. API-server scraping uses
the existing `kubernetes` Service in `default` and is disabled by default; set
`api_server = true` only when it is wanted.

The controller-manager, scheduler, and optional API-server endpoints use the
mounted service-account token only with CA-verified HTTPS. CoreDNS, kube-proxy,
and the default HTTP etcd endpoint receive no service-account credential.
Self-managed clusters enable these components and set `controller_manager_tls`
and `scheduler_tls` to their mounted CA path and certificate server name. Setting
`insecure_skip_verify = true` is an explicit compatibility opt-in. Many kubeadm
installations use component-serving certificates that are not signed by the
service-account CA, so these overrides and post-apply target checks matter.

These native component objects are suppressed when `agent_standalone = false`.
That is the dual-backend path: the Operator converter consumes the component
ServiceMonitors produced by kube-prometheus-stack, without duplicate native
targets. On managed EKS, AWS does not expose controller-manager, scheduler, or
etcd pods in the workload cluster, so those three Services may have no
endpoints; CoreDNS and kube-proxy remain useful. Output booleans describe
rendered configuration, not runtime target health.

## Operational defaults

The module renders these write-path defaults:

- vminsert requests: `500m` CPU and `512Mi` memory; limits: `2` CPU and `1Gi` memory;
- vmstorage requests: `500m` CPU and `1Gi` memory; limits: `1` CPU and `2Gi` memory;
- VMAgent requests: `1` CPU and `512Mi` memory; limits: `2` CPU and `1Gi` memory;
- VMAgent `extraArgs.remoteWrite.queues`: `16`.

`extra_configs` can override non-endpoint VictoriaMetrics cluster values. A
final module-owned values document protects vminsert/vmselect enablement,
explicit release-derived full names, HTTP port names/listen addresses, and
Service ports/target ports/types so the derived VMAgent and Grafana URLs remain
valid without changing vmstorage naming. For vmagent, partial maps under `agent_extra_configs.resources` and
`agent_extra_configs.extraArgs` override only supplied keys and retain the
remaining defaults.

The module does not enable persistent storage for VMAgent. If its queue uses
`emptyDir` for `/tmpData`, a rollout discards queued-but-not-yet-written
samples. Check `max(vmagent_remotewrite_pending_data_bytes) == 0` before
switching or rolling back, or configure persistent queue storage separately.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.3 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~> 2.17 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_helm"></a> [helm](#provider\_helm) | 2.17.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [helm_release.victoria_metrics](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.victoria_metrics_operator](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.victoria_metrics_resources](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_agent_cadvisor_scrape_enabled"></a> [agent\_cadvisor\_scrape\_enabled](#input\_agent\_cadvisor\_scrape\_enabled) | Whether the active VMAgent renders a native VMNodeScrape for the kubelet /metrics/cadvisor endpoint. | `bool` | `true` | no |
| <a name="input_agent_enabled"></a> [agent\_enabled](#input\_agent\_enabled) | Whether to render the VMAgent custom resource as the active Kubernetes scraper. | `bool` | `false` | no |
| <a name="input_agent_extra_configs"></a> [agent\_extra\_configs](#input\_agent\_extra\_configs) | Non-protected VMAgent spec overrides. | `any` | `{}` | no |
| <a name="input_agent_extra_scrape_configs"></a> [agent\_extra\_scrape\_configs](#input\_agent\_extra\_scrape\_configs) | Non-secret inlineScrapeConfig entries for the VMAgent custom resource; direct child callers replacing a module integration must disable its matching agent\_*\_enabled input. | `any` | `[]` | no |
| <a name="input_agent_kube_state_metrics_enabled"></a> [agent\_kube\_state\_metrics\_enabled](#input\_agent\_kube\_state\_metrics\_enabled) | Whether to render the native KSM VMServiceScrape when the remaining collector and exporter gates also pass. | `bool` | `true` | no |
| <a name="input_agent_kube_state_metrics_fullname"></a> [agent\_kube\_state\_metrics\_fullname](#input\_agent\_kube\_state\_metrics\_fullname) | Resolved name of the independent kube-state-metrics Service; the native VMServiceScrape adds a victoria-metrics suffix to avoid converter ownership collisions. | `string` | `"prometheus-kube-state-metrics"` | no |
| <a name="input_agent_kube_state_metrics_namespace"></a> [agent\_kube\_state\_metrics\_namespace](#input\_agent\_kube\_state\_metrics\_namespace) | Namespace containing the independent kube-state-metrics Service. | `string` | `"monitoring"` | no |
| <a name="input_agent_kube_state_metrics_release_name"></a> [agent\_kube\_state\_metrics\_release\_name](#input\_agent\_kube\_state\_metrics\_release\_name) | Helm instance label of the independent kube-state-metrics Service. | `string` | `"kube-state-metrics"` | no |
| <a name="input_agent_kubelet_metrics"></a> [agent\_kubelet\_metrics](#input\_agent\_kubelet\_metrics) | Union of metric-name patterns retained from native node scrapes; known patterns are routed to matching kubelet, cAdvisor, or resource endpoints, while unknown patterns apply to all enabled endpoints. | `list(string)` | <pre>[<br/>  "container_cpu_.*",<br/>  "container_memory_.*",<br/>  "container_network_.*",<br/>  "pod_cpu_usage_seconds_total",<br/>  "pod_memory_working_set_bytes",<br/>  "kubelet_volume_stats.*",<br/>  "volume_operation_total_seconds.*",<br/>  "container_fs_.*"<br/>]</pre> | no |
| <a name="input_agent_kubelet_scrape_enabled"></a> [agent\_kubelet\_scrape\_enabled](#input\_agent\_kubelet\_scrape\_enabled) | Whether the active VMAgent renders a native VMNodeScrape for the kubelet /metrics endpoint. | `bool` | `true` | no |
| <a name="input_agent_kubernetes_component_scrapes"></a> [agent\_kubernetes\_component\_scrapes](#input\_agent\_kubernetes\_component\_scrapes) | Native Kubernetes component discovery rendered only for a standalone VictoriaMetrics collector. | <pre>object({<br/>    namespace            = optional(string, "kube-system")<br/>    api_server_namespace = optional(string, "default")<br/>    api_server           = optional(bool, false)<br/>    core_dns             = optional(bool, true)<br/>    kube_proxy           = optional(bool, true)<br/>    controller_manager   = optional(bool, false)<br/>    scheduler            = optional(bool, false)<br/>    etcd                 = optional(bool, true)<br/>    controller_manager_tls = optional(object({<br/>      ca_file              = optional(string, null)<br/>      server_name          = optional(string, null)<br/>      insecure_skip_verify = optional(bool, false)<br/>    }), null)<br/>    scheduler_tls = optional(object({<br/>      ca_file              = optional(string, null)<br/>      server_name          = optional(string, null)<br/>      insecure_skip_verify = optional(bool, false)<br/>    }), null)<br/>  })</pre> | `{}` | no |
| <a name="input_agent_loki_enabled"></a> [agent\_loki\_enabled](#input\_agent\_loki\_enabled) | Whether to render a native Loki VMServiceScrape. | `bool` | `false` | no |
| <a name="input_agent_loki_namespace"></a> [agent\_loki\_namespace](#input\_agent\_loki\_namespace) | Namespace containing Loki. | `string` | `"monitoring"` | no |
| <a name="input_agent_loki_release_name"></a> [agent\_loki\_release\_name](#input\_agent\_loki\_release\_name) | Loki Helm release name used by native discovery. | `string` | `"loki"` | no |
| <a name="input_agent_name"></a> [agent\_name](#input\_agent\_name) | Name of the selector-managed VMAgent custom resource. | `string` | `"victoria-metrics-agent"` | no |
| <a name="input_agent_node_exporter_enabled"></a> [agent\_node\_exporter\_enabled](#input\_agent\_node\_exporter\_enabled) | Whether to render the native node-exporter VMServiceScrape when VMAgent is active. | `bool` | `false` | no |
| <a name="input_agent_node_exporter_fullname"></a> [agent\_node\_exporter\_fullname](#input\_agent\_node\_exporter\_fullname) | Resolved name of the independent node-exporter Service. | `string` | `"prometheus-node-exporter"` | no |
| <a name="input_agent_node_exporter_namespace"></a> [agent\_node\_exporter\_namespace](#input\_agent\_node\_exporter\_namespace) | Namespace containing the independent node-exporter Service. | `string` | `"monitoring"` | no |
| <a name="input_agent_node_exporter_release_name"></a> [agent\_node\_exporter\_release\_name](#input\_agent\_node\_exporter\_release\_name) | Helm instance label of the independent node-exporter Service. | `string` | `"node-exporter"` | no |
| <a name="input_agent_replica_count"></a> [agent\_replica\_count](#input\_agent\_replica\_count) | Replica count for the selector-managed VMAgent custom resource. | `number` | `1` | no |
| <a name="input_agent_resource_scrape_enabled"></a> [agent\_resource\_scrape\_enabled](#input\_agent\_resource\_scrape\_enabled) | Whether the active VMAgent renders the optional kubelet /metrics/resource VMNodeScrape. | `bool` | `false` | no |
| <a name="input_agent_standalone"></a> [agent\_standalone](#input\_agent\_standalone) | Whether VMAgent runs without kube-prometheus-stack and must own native Kubernetes component discovery. | `bool` | `false` | no |
| <a name="input_agent_tempo_enabled"></a> [agent\_tempo\_enabled](#input\_agent\_tempo\_enabled) | Whether to render a native Tempo VMServiceScrape. | `bool` | `false` | no |
| <a name="input_agent_tempo_namespace"></a> [agent\_tempo\_namespace](#input\_agent\_tempo\_namespace) | Namespace containing Tempo. | `string` | `"monitoring"` | no |
| <a name="input_agent_tempo_query_enabled"></a> [agent\_tempo\_query\_enabled](#input\_agent\_tempo\_query\_enabled) | Whether Tempo Query exposes the optional jaeger-metrics port. | `bool` | `false` | no |
| <a name="input_agent_tempo_release_name"></a> [agent\_tempo\_release\_name](#input\_agent\_tempo\_release\_name) | Tempo Helm release name used by native discovery. | `string` | `"tempo"` | no |
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | victoria metrics cluster chart version | `string` | `"0.31.0"` | no |
| <a name="input_configs"></a> [configs](#input\_configs) | Values to send to VictoriaMetrics helm chart | <pre>object({<br/>    retention_period = optional(string, "30d")<br/>    vmstorage = optional(object({<br/>      replica_count = optional(number, 3)<br/>      storage_class = optional(string, "")<br/>      storage_size  = optional(string, "100Gi")<br/>      access_modes  = optional(list(string), ["ReadWriteOnce"])<br/>    }), {})<br/>    vminsert = optional(object({<br/>      replica_count = optional(number, 2)<br/>    }), {})<br/>    vmselect = optional(object({<br/>      replica_count = optional(number, 2)<br/>    }), {})<br/>  })</pre> | `{}` | no |
| <a name="input_create_namespace"></a> [create\_namespace](#input\_create\_namespace) | Whether create namespace if not exist | `bool` | `true` | no |
| <a name="input_extra_configs"></a> [extra\_configs](#input\_extra\_configs) | Additional VictoriaMetrics cluster values. The derived vminsert/vmselect service identity and port contract takes precedence. | `any` | `{}` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | namespace to use for deployment | `string` | `"monitoring"` | no |
| <a name="input_operator_chart_version"></a> [operator\_chart\_version](#input\_operator\_chart\_version) | Pinned VictoriaMetrics Operator Helm chart version. | `string` | `"0.67.2"` | no |
| <a name="input_operator_enabled"></a> [operator\_enabled](#input\_operator\_enabled) | Whether to install the VictoriaMetrics Operator, its CRDs/RBAC, and the dependent custom-resource release. | `bool` | `false` | no |
| <a name="input_operator_extra_configs"></a> [operator\_extra\_configs](#input\_operator\_extra\_configs) | Non-protected VictoriaMetrics Operator chart overrides. | `any` | `{}` | no |
| <a name="input_operator_release_name"></a> [operator\_release\_name](#input\_operator\_release\_name) | VictoriaMetrics Operator Helm release name. | `string` | `"victoria-metrics-operator"` | no |
| <a name="input_prometheus_converter_enabled"></a> [prometheus\_converter\_enabled](#input\_prometheus\_converter\_enabled) | Whether the Operator converts Prometheus monitor resources during a dual-backend migration. | `bool` | `true` | no |
| <a name="input_release_name"></a> [release\_name](#input\_release\_name) | victoria metrics release name | `string` | `"victoria-metrics"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_helm_metadata"></a> [helm\_metadata](#output\_helm\_metadata) | victoria metrics helm release metadata |
| <a name="output_native_kubernetes_component_scrapes"></a> [native\_kubernetes\_component\_scrapes](#output\_native\_kubernetes\_component\_scrapes) | Rendered native Kubernetes component discovery state; these booleans do not report runtime target health. |
| <a name="output_native_node_scrapes"></a> [native\_node\_scrapes](#output\_native\_node\_scrapes) | Resolved native VMNodeScrape activation state. |
| <a name="output_operator_release"></a> [operator\_release](#output\_operator\_release) | Non-sensitive identity of the VictoriaMetrics Operator release. |
| <a name="output_prometheus_converter_enabled"></a> [prometheus\_converter\_enabled](#output\_prometheus\_converter\_enabled) | Whether Prometheus monitor conversion is enabled for dual-backend migration compatibility. |
| <a name="output_resource_objects"></a> [resource\_objects](#output\_resource\_objects) | Non-sensitive identities of resources managed by the ordered custom-resource release. |
| <a name="output_resources_release"></a> [resources\_release](#output\_resources\_release) | Non-sensitive identity of the Helm release that creates VictoriaMetrics custom-resource instances after the Operator CRDs. |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.3 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~> 2.17 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_helm"></a> [helm](#provider\_helm) | ~> 2.17 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [helm_release.victoria_metrics](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.victoria_metrics_operator](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.victoria_metrics_resources](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_agent_cadvisor_scrape_enabled"></a> [agent\_cadvisor\_scrape\_enabled](#input\_agent\_cadvisor\_scrape\_enabled) | Whether the active VMAgent renders a native VMNodeScrape for the kubelet /metrics/cadvisor endpoint. | `bool` | `true` | no |
| <a name="input_agent_enabled"></a> [agent\_enabled](#input\_agent\_enabled) | Whether to render the VMAgent custom resource as the active Kubernetes scraper. | `bool` | `false` | no |
| <a name="input_agent_extra_configs"></a> [agent\_extra\_configs](#input\_agent\_extra\_configs) | Non-protected VMAgent spec overrides. | `any` | `{}` | no |
| <a name="input_agent_extra_scrape_configs"></a> [agent\_extra\_scrape\_configs](#input\_agent\_extra\_scrape\_configs) | Non-secret inlineScrapeConfig entries for the VMAgent custom resource. | `any` | `[]` | no |
| <a name="input_agent_kube_state_metrics_enabled"></a> [agent\_kube\_state\_metrics\_enabled](#input\_agent\_kube\_state\_metrics\_enabled) | Whether to render the native KSM VMServiceScrape when the remaining collector and exporter gates also pass. | `bool` | `true` | no |
| <a name="input_agent_kube_state_metrics_fullname"></a> [agent\_kube\_state\_metrics\_fullname](#input\_agent\_kube\_state\_metrics\_fullname) | Resolved name of the independent kube-state-metrics Service; the native VMServiceScrape adds a victoria-metrics suffix to avoid converter ownership collisions. | `string` | `"prometheus-kube-state-metrics"` | no |
| <a name="input_agent_kube_state_metrics_namespace"></a> [agent\_kube\_state\_metrics\_namespace](#input\_agent\_kube\_state\_metrics\_namespace) | Namespace containing the independent kube-state-metrics Service. | `string` | `"monitoring"` | no |
| <a name="input_agent_kube_state_metrics_release_name"></a> [agent\_kube\_state\_metrics\_release\_name](#input\_agent\_kube\_state\_metrics\_release\_name) | Helm instance label of the independent kube-state-metrics Service. | `string` | `"kube-state-metrics"` | no |
| <a name="input_agent_kubelet_metrics"></a> [agent\_kubelet\_metrics](#input\_agent\_kubelet\_metrics) | Union of metric-name patterns retained from native node scrapes; known patterns are routed to matching kubelet, cAdvisor, or resource endpoints, while unknown patterns apply to all enabled endpoints. | `list(string)` | <pre>[<br/>  "container_cpu_.*",<br/>  "container_memory_.*",<br/>  "container_network_.*",<br/>  "pod_cpu_usage_seconds_total",<br/>  "pod_memory_working_set_bytes",<br/>  "kubelet_volume_stats.*",<br/>  "volume_operation_total_seconds.*",<br/>  "container_fs_.*"<br/>]</pre> | no |
| <a name="input_agent_kubelet_scrape_enabled"></a> [agent\_kubelet\_scrape\_enabled](#input\_agent\_kubelet\_scrape\_enabled) | Whether the active VMAgent renders a native VMNodeScrape for the kubelet /metrics endpoint. | `bool` | `true` | no |
| <a name="input_agent_kubernetes_component_scrapes"></a> [agent\_kubernetes\_component\_scrapes](#input\_agent\_kubernetes\_component\_scrapes) | Native Kubernetes component discovery rendered only for a standalone VictoriaMetrics collector. | <pre>object({<br/>    namespace            = optional(string, "kube-system")<br/>    api_server_namespace = optional(string, "default")<br/>    api_server           = optional(bool, false)<br/>    core_dns             = optional(bool, true)<br/>    kube_proxy           = optional(bool, true)<br/>    controller_manager   = optional(bool, false)<br/>    scheduler            = optional(bool, false)<br/>    etcd                 = optional(bool, true)<br/>    controller_manager_tls = optional(object({<br/>      ca_file              = optional(string, null)<br/>      server_name          = optional(string, null)<br/>      insecure_skip_verify = optional(bool, false)<br/>    }), null)<br/>    scheduler_tls = optional(object({<br/>      ca_file              = optional(string, null)<br/>      server_name          = optional(string, null)<br/>      insecure_skip_verify = optional(bool, false)<br/>    }), null)<br/>  })</pre> | `{}` | no |
| <a name="input_agent_loki_enabled"></a> [agent\_loki\_enabled](#input\_agent\_loki\_enabled) | Whether to render a native Loki VMServiceScrape. | `bool` | `false` | no |
| <a name="input_agent_loki_namespace"></a> [agent\_loki\_namespace](#input\_agent\_loki\_namespace) | Namespace containing Loki. | `string` | `"monitoring"` | no |
| <a name="input_agent_loki_release_name"></a> [agent\_loki\_release\_name](#input\_agent\_loki\_release\_name) | Loki Helm release name used by native discovery. | `string` | `"loki"` | no |
| <a name="input_agent_name"></a> [agent\_name](#input\_agent\_name) | Name of the selector-managed VMAgent custom resource. | `string` | `"victoria-metrics-agent"` | no |
| <a name="input_agent_node_exporter_enabled"></a> [agent\_node\_exporter\_enabled](#input\_agent\_node\_exporter\_enabled) | Whether to render the native node-exporter VMServiceScrape when VMAgent is active. | `bool` | `false` | no |
| <a name="input_agent_node_exporter_fullname"></a> [agent\_node\_exporter\_fullname](#input\_agent\_node\_exporter\_fullname) | Resolved name of the independent node-exporter Service. | `string` | `"prometheus-node-exporter"` | no |
| <a name="input_agent_node_exporter_namespace"></a> [agent\_node\_exporter\_namespace](#input\_agent\_node\_exporter\_namespace) | Namespace containing the independent node-exporter Service. | `string` | `"monitoring"` | no |
| <a name="input_agent_node_exporter_release_name"></a> [agent\_node\_exporter\_release\_name](#input\_agent\_node\_exporter\_release\_name) | Helm instance label of the independent node-exporter Service. | `string` | `"node-exporter"` | no |
| <a name="input_agent_replica_count"></a> [agent\_replica\_count](#input\_agent\_replica\_count) | Replica count for the selector-managed VMAgent custom resource. | `number` | `1` | no |
| <a name="input_agent_resource_scrape_enabled"></a> [agent\_resource\_scrape\_enabled](#input\_agent\_resource\_scrape\_enabled) | Whether the active VMAgent renders the optional kubelet /metrics/resource VMNodeScrape. | `bool` | `false` | no |
| <a name="input_agent_standalone"></a> [agent\_standalone](#input\_agent\_standalone) | Whether VMAgent runs without kube-prometheus-stack and must own native Kubernetes component discovery. | `bool` | `false` | no |
| <a name="input_agent_tempo_enabled"></a> [agent\_tempo\_enabled](#input\_agent\_tempo\_enabled) | Whether to render a native Tempo VMServiceScrape. | `bool` | `false` | no |
| <a name="input_agent_tempo_namespace"></a> [agent\_tempo\_namespace](#input\_agent\_tempo\_namespace) | Namespace containing Tempo. | `string` | `"monitoring"` | no |
| <a name="input_agent_tempo_query_enabled"></a> [agent\_tempo\_query\_enabled](#input\_agent\_tempo\_query\_enabled) | Whether Tempo Query exposes the optional jaeger-metrics port. | `bool` | `false` | no |
| <a name="input_agent_tempo_release_name"></a> [agent\_tempo\_release\_name](#input\_agent\_tempo\_release\_name) | Tempo Helm release name used by native discovery. | `string` | `"tempo"` | no |
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | victoria metrics cluster chart version | `string` | `"0.31.0"` | no |
| <a name="input_configs"></a> [configs](#input\_configs) | Values to send to VictoriaMetrics helm chart | <pre>object({<br/>    retention_period = optional(string, "30d")<br/>    vmstorage = optional(object({<br/>      replica_count = optional(number, 3)<br/>      storage_class = optional(string, "")<br/>      storage_size  = optional(string, "100Gi")<br/>      access_modes  = optional(list(string), ["ReadWriteOnce"])<br/>    }), {})<br/>    vminsert = optional(object({<br/>      replica_count = optional(number, 2)<br/>    }), {})<br/>    vmselect = optional(object({<br/>      replica_count = optional(number, 2)<br/>    }), {})<br/>  })</pre> | `{}` | no |
| <a name="input_create_namespace"></a> [create\_namespace](#input\_create\_namespace) | Whether create namespace if not exist | `bool` | `true` | no |
| <a name="input_extra_configs"></a> [extra\_configs](#input\_extra\_configs) | Additional VictoriaMetrics cluster values. The derived vminsert/vmselect service identity and port contract takes precedence. | `any` | `{}` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | namespace to use for deployment | `string` | `"monitoring"` | no |
| <a name="input_operator_chart_version"></a> [operator\_chart\_version](#input\_operator\_chart\_version) | Pinned VictoriaMetrics Operator Helm chart version. | `string` | `"0.67.2"` | no |
| <a name="input_operator_enabled"></a> [operator\_enabled](#input\_operator\_enabled) | Whether to install the VictoriaMetrics Operator, its CRDs/RBAC, and the dependent custom-resource release. | `bool` | `false` | no |
| <a name="input_operator_extra_configs"></a> [operator\_extra\_configs](#input\_operator\_extra\_configs) | Non-protected VictoriaMetrics Operator chart overrides. | `any` | `{}` | no |
| <a name="input_operator_release_name"></a> [operator\_release\_name](#input\_operator\_release\_name) | VictoriaMetrics Operator Helm release name. | `string` | `"victoria-metrics-operator"` | no |
| <a name="input_prometheus_converter_enabled"></a> [prometheus\_converter\_enabled](#input\_prometheus\_converter\_enabled) | Whether the Operator converts Prometheus monitor resources during a dual-backend migration. | `bool` | `true` | no |
| <a name="input_release_name"></a> [release\_name](#input\_release\_name) | victoria metrics release name | `string` | `"victoria-metrics"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_helm_metadata"></a> [helm\_metadata](#output\_helm\_metadata) | victoria metrics helm release metadata |
| <a name="output_native_kubernetes_component_scrapes"></a> [native\_kubernetes\_component\_scrapes](#output\_native\_kubernetes\_component\_scrapes) | Rendered native Kubernetes component discovery state; these booleans do not report runtime target health. |
| <a name="output_native_node_scrapes"></a> [native\_node\_scrapes](#output\_native\_node\_scrapes) | Resolved native VMNodeScrape activation state. |
| <a name="output_operator_release"></a> [operator\_release](#output\_operator\_release) | Non-sensitive identity of the VictoriaMetrics Operator release. |
| <a name="output_prometheus_converter_enabled"></a> [prometheus\_converter\_enabled](#output\_prometheus\_converter\_enabled) | Whether Prometheus monitor conversion is enabled for dual-backend migration compatibility. |
| <a name="output_resource_objects"></a> [resource\_objects](#output\_resource\_objects) | Non-sensitive identities of resources managed by the ordered custom-resource release. |
| <a name="output_resources_release"></a> [resources\_release](#output\_resources\_release) | Non-sensitive identity of the Helm release that creates VictoriaMetrics custom-resource instances after the Operator CRDs. |
<!-- END_TF_DOCS -->
