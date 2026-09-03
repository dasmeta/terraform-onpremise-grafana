# Independent node-exporter

Installs the Prometheus Community `prometheus-node-exporter` chart independently
from `kube-prometheus-stack`. This keeps node metrics available when the root
module switches between Prometheus and VictoriaMetrics.

The root selector controls discovery: Prometheus mode enables this chart's
`ServiceMonitor`; VictoriaMetrics mode disables it and creates a native
`VMServiceScrape` through the VictoriaMetrics child. Annotation scraping is
always disabled to prevent duplicate samples.

Defaults preserve the stable `prometheus-node-exporter` Service identity,
chart version `4.47.1`, port `metrics:9100`, requests `100m/200Mi`, and limits
`200m/500Mi`. `extra_configs` is applied first; identity, resources, and scrape
ownership remain selector-owned.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
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
| [helm_release.node_exporter](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | Pinned Prometheus Community prometheus-node-exporter chart version. | `string` | `"4.47.1"` | no |
| <a name="input_create_namespace"></a> [create\_namespace](#input\_create\_namespace) | Whether Helm may create the target namespace. | `bool` | `true` | no |
| <a name="input_extra_configs"></a> [extra\_configs](#input\_extra\_configs) | Additional chart values applied before selector-owned identity, resources, and scrape settings. | `any` | `{}` | no |
| <a name="input_fullname_override"></a> [fullname\_override](#input\_fullname\_override) | Stable full name used for node-exporter resources and Service discovery. | `string` | `"prometheus-node-exporter"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace where node-exporter is deployed. | `string` | `"monitoring"` | no |
| <a name="input_prometheus_monitor_enabled"></a> [prometheus\_monitor\_enabled](#input\_prometheus\_monitor\_enabled) | Whether the independent chart creates the active Prometheus ServiceMonitor. | `bool` | `true` | no |
| <a name="input_prometheus_release_name"></a> [prometheus\_release\_name](#input\_prometheus\_release\_name) | Prometheus Helm release label selected by the Prometheus custom resource. | `string` | `"prometheus"` | no |
| <a name="input_release_name"></a> [release\_name](#input\_release\_name) | Independent node-exporter Helm release name. | `string` | `"node-exporter"` | no |
| <a name="input_resources"></a> [resources](#input\_resources) | Node-exporter container requests and limits. | <pre>object({<br/>    requests = optional(object({<br/>      cpu    = optional(string, "100m")<br/>      memory = optional(string, "200Mi")<br/>    }), {})<br/>    limits = optional(object({<br/>      cpu    = optional(string, "200m")<br/>      memory = optional(string, "500Mi")<br/>    }), {})<br/>  })</pre> | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_helm_metadata"></a> [helm\_metadata](#output\_helm\_metadata) | node-exporter Helm release metadata. |
| <a name="output_prometheus_monitor_enabled"></a> [prometheus\_monitor\_enabled](#output\_prometheus\_monitor\_enabled) | Resolved Prometheus ServiceMonitor activation state. |
| <a name="output_release"></a> [release](#output\_release) | Non-sensitive identity of the independent node-exporter release. |
| <a name="output_service_target"></a> [service\_target](#output\_service\_target) | In-cluster node-exporter scrape target. |
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
| [helm_release.node_exporter](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | Pinned Prometheus Community prometheus-node-exporter chart version. | `string` | `"4.47.1"` | no |
| <a name="input_create_namespace"></a> [create\_namespace](#input\_create\_namespace) | Whether Helm may create the target namespace. | `bool` | `true` | no |
| <a name="input_extra_configs"></a> [extra\_configs](#input\_extra\_configs) | Additional chart values applied before selector-owned identity, resources, and scrape settings. | `any` | `{}` | no |
| <a name="input_fullname_override"></a> [fullname\_override](#input\_fullname\_override) | Stable full name used for node-exporter resources and Service discovery. | `string` | `"prometheus-node-exporter"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace where node-exporter is deployed. | `string` | `"monitoring"` | no |
| <a name="input_prometheus_monitor_enabled"></a> [prometheus\_monitor\_enabled](#input\_prometheus\_monitor\_enabled) | Whether the independent chart creates the active Prometheus ServiceMonitor. | `bool` | `true` | no |
| <a name="input_prometheus_release_name"></a> [prometheus\_release\_name](#input\_prometheus\_release\_name) | Prometheus Helm release label selected by the Prometheus custom resource. | `string` | `"prometheus"` | no |
| <a name="input_release_name"></a> [release\_name](#input\_release\_name) | Independent node-exporter Helm release name. | `string` | `"node-exporter"` | no |
| <a name="input_resources"></a> [resources](#input\_resources) | Node-exporter container requests and limits. | <pre>object({<br/>    requests = optional(object({<br/>      cpu    = optional(string, "100m")<br/>      memory = optional(string, "200Mi")<br/>    }), {})<br/>    limits = optional(object({<br/>      cpu    = optional(string, "200m")<br/>      memory = optional(string, "500Mi")<br/>    }), {})<br/>  })</pre> | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_helm_metadata"></a> [helm\_metadata](#output\_helm\_metadata) | node-exporter Helm release metadata. |
| <a name="output_prometheus_monitor_enabled"></a> [prometheus\_monitor\_enabled](#output\_prometheus\_monitor\_enabled) | Resolved Prometheus ServiceMonitor activation state. |
| <a name="output_release"></a> [release](#output\_release) | Non-sensitive identity of the independent node-exporter release. |
| <a name="output_service_target"></a> [service\_target](#output\_service\_target) | In-cluster node-exporter scrape target. |
<!-- END_TF_DOCS -->
