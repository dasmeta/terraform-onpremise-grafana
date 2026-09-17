# consumer_lag

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

No requirements.

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_base"></a> [base](#module\_base) | ../../base | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cluster"></a> [cluster](#input\_cluster) | Optional cluster label value | `string` | `""` | no |
| <a name="input_cluster_label"></a> [cluster\_label](#input\_cluster\_label) | Optional cluster label name when exporters expose a cluster identity | `string` | `""` | no |
| <a name="input_coordinates"></a> [coordinates](#input\_coordinates) | Panel coordinates | <pre>object({<br/>    x : number<br/>    y : number<br/>    width : number<br/>    height : number<br/>  })</pre> | n/a | yes |
| <a name="input_datasource_uid"></a> [datasource\_uid](#input\_datasource\_uid) | Prometheus datasource UID | `string` | `"prometheus"` | no |
| <a name="input_extra_filters"></a> [extra\_filters](#input\_extra\_filters) | Additional PromQL label matchers, for example job=~"kafka-exporter" | `string` | `""` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Kubernetes namespace used to select Kafka exporter metrics | `string` | n/a | yes |
| <a name="input_period"></a> [period](#input\_period) | Prometheus range interval | `string` | `"$__rate_interval"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_data"></a> [data](#output\_data) | Grafana panel payload |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
