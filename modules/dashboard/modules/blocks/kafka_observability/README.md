# kafka_observability

Reusable Grafana dashboard block for Kafka Connect status-exporter metrics.

Row type: `block/kafka_observability`

Consumer lag alerts belong on `block/msk` (CloudWatch). This block does not accept consumer-group lag inputs.

Required:

- `namespace`

Optional:

- `datasource_uid` (defaults to the dashboard Prometheus UID)
- `extra_filters` additional PromQL matchers
- `cluster_label` / `cluster` when exporters expose a cluster identity
- `stopped_connectors` to exclude intentional stopped or paused connectors from FAILED alerts
- `alerts` Grafana-managed alert configuration

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

No requirements.

## Providers

No providers.

## Modules

No modules.

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_block_name"></a> [block\_name](#input\_block\_name) | Dashboard block title | `string` | `"Kafka observability"` | no |
| <a name="input_cluster"></a> [cluster](#input\_cluster) | Optional cluster label value | `string` | `""` | no |
| <a name="input_cluster_label"></a> [cluster\_label](#input\_cluster\_label) | Optional cluster label name when exporters expose a cluster identity | `string` | `""` | no |
| <a name="input_datasource_uid"></a> [datasource\_uid](#input\_datasource\_uid) | Prometheus datasource UID | `string` | `"prometheus"` | no |
| <a name="input_extra_filters"></a> [extra\_filters](#input\_extra\_filters) | Additional PromQL label matchers shared by dashboard panels, for example job=~"example-connect-status-exporter" | `string` | `""` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Kubernetes namespace used to select kafka-connect-status-exporter metrics | `string` | n/a | yes |
| <a name="input_period"></a> [period](#input\_period) | Prometheus range interval used by trend panels | `string` | `"$__rate_interval"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_result"></a> [result](#output\_result) | Kafka observability dashboard block widget rows |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
