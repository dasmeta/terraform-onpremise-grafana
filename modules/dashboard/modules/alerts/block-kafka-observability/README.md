# block-kafka-observability

Grafana-managed Prometheus alerts for `block/kafka_observability`.

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
| <a name="input_alerts"></a> [alerts](#input\_alerts) | Per-rule Kafka observability alert configuration. Supported keys: enabled, pending\_period, labels, annotations, consumer\_group\_lag, connector\_failed, task\_failed, connect\_rest\_down, exporter\_scrape. | `any` | `{}` | no |
| <a name="input_cluster"></a> [cluster](#input\_cluster) | Optional cluster label value | `string` | `""` | no |
| <a name="input_cluster_label"></a> [cluster\_label](#input\_cluster\_label) | Optional cluster label name when exporters expose a cluster identity | `string` | `""` | no |
| <a name="input_critical_consumer_groups"></a> [critical\_consumer\_groups](#input\_critical\_consumer\_groups) | Consumer groups that must stay active | `list(string)` | `[]` | no |
| <a name="input_dashboard_url"></a> [dashboard\_url](#input\_dashboard\_url) | Optional dashboard URL annotation | `string` | `""` | no |
| <a name="input_datasource"></a> [datasource](#input\_datasource) | Prometheus datasource UID | `string` | `"prometheus"` | no |
| <a name="input_defaults"></a> [defaults](#input\_defaults) | Shared alert defaults merged into each rule. Supported keys: enabled, group, pending\_period, labels, no\_data\_state, exec\_err\_state. | `any` | `{}` | no |
| <a name="input_exporter_scrape_filters"></a> [exporter\_scrape\_filters](#input\_exporter\_scrape\_filters) | Optional PromQL matchers for the exporter scrape alert; defaults to extra\_filters when empty | `string` | `""` | no |
| <a name="input_extra_filters"></a> [extra\_filters](#input\_extra\_filters) | Additional PromQL label matchers shared by alert queries | `string` | `""` | no |
| <a name="input_failed_state"></a> [failed\_state](#input\_failed\_state) | Connector/task state label value treated as failed | `string` | `"FAILED"` | no |
| <a name="input_idle_consumer_groups"></a> [idle\_consumer\_groups](#input\_idle\_consumer\_groups) | Consumer groups that are intentionally idle and are excluded from empty-member alerts | `list(string)` | `[]` | no |
| <a name="input_lag_growth_window"></a> [lag\_growth\_window](#input\_lag\_growth\_window) | Range window used with increase(kafka\_consumergroup\_lag[window]) | `string` | `"15m"` | no |
| <a name="input_lag_threshold"></a> [lag\_threshold](#input\_lag\_threshold) | Minimum lag growth required to fire the empty-member alert | `number` | `0` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Kubernetes namespace used to select Kafka exporter and Kafka Connect exporter metrics | `string` | n/a | yes |
| <a name="input_pending_period"></a> [pending\_period](#input\_pending\_period) | Default alert pending duration | `string` | `"5m"` | no |
| <a name="input_runbook_url"></a> [runbook\_url](#input\_runbook\_url) | Optional runbook URL annotation | `string` | `""` | no |
| <a name="input_stopped_connectors"></a> [stopped\_connectors](#input\_stopped\_connectors) | Connectors that are intentionally stopped and are excluded from FAILED alerts | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_alert_rules"></a> [alert\_rules](#output\_alert\_rules) | Grafana-managed Kafka observability alert rules |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
