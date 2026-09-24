# block-kafka-observability

Grafana-managed Prometheus alerts for `block/kafka_observability`.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

No requirements.

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_scrape_selector"></a> [scrape\_selector](#module\_scrape\_selector) | ../../widgets/kafka/selector | n/a |
| <a name="module_selector"></a> [selector](#module\_selector) | ../../widgets/kafka/selector | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_alerts"></a> [alerts](#input\_alerts) | Per-rule Kafka Connect alert configuration. Supported keys: enabled, pending\_period, labels, annotations, connector\_failed, task\_failed, connect\_rest\_down, exporter\_scrape. Rules stay off unless this row sets alerts.enabled = true. Dashboard-level alerts.enabled is ignored. | `any` | `{}` | no |
| <a name="input_cluster"></a> [cluster](#input\_cluster) | Optional cluster label value | `string` | `""` | no |
| <a name="input_cluster_label"></a> [cluster\_label](#input\_cluster\_label) | Optional cluster label name when exporters expose a cluster identity | `string` | `""` | no |
| <a name="input_dashboard_url"></a> [dashboard\_url](#input\_dashboard\_url) | Optional dashboard URL annotation | `string` | `""` | no |
| <a name="input_datasource"></a> [datasource](#input\_datasource) | Prometheus datasource UID | `string` | `"prometheus"` | no |
| <a name="input_defaults"></a> [defaults](#input\_defaults) | Shared alert defaults merged into each rule. Supported keys: enabled, group, pending\_period, labels, no\_data\_state, exec\_err\_state. | `any` | `{}` | no |
| <a name="input_exporter_scrape_filters"></a> [exporter\_scrape\_filters](#input\_exporter\_scrape\_filters) | Optional PromQL matchers for the exporter scrape alert; defaults to extra\_filters when empty | `string` | `""` | no |
| <a name="input_extra_filters"></a> [extra\_filters](#input\_extra\_filters) | Additional PromQL label matchers shared by alert queries | `string` | `""` | no |
| <a name="input_failed_state"></a> [failed\_state](#input\_failed\_state) | Connector/task state label value treated as failed. kafka-connect-status-exporter emits lowercase Connect states. | `string` | `"failed"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Kubernetes namespace used to select kafka-connect-status-exporter metrics | `string` | n/a | yes |
| <a name="input_pending_period"></a> [pending\_period](#input\_pending\_period) | Default alert pending duration | `string` | `"5m"` | no |
| <a name="input_runbook_url"></a> [runbook\_url](#input\_runbook\_url) | Optional runbook URL annotation | `string` | `""` | no |
| <a name="input_stopped_connectors"></a> [stopped\_connectors](#input\_stopped\_connectors) | Connectors that are intentionally stopped and are excluded from FAILED alerts | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_alert_rules"></a> [alert\_rules](#output\_alert\_rules) | Grafana-managed Kafka Connect status-exporter alert rules |
| <a name="output_connect_rest_expr"></a> [connect\_rest\_expr](#output\_connect\_rest\_expr) | Rendered PromQL for Kafka Connect REST down alerts |
| <a name="output_connector_failed_expr"></a> [connector\_failed\_expr](#output\_connector\_failed\_expr) | Rendered PromQL for connector failed-state alerts |
| <a name="output_exporter_scrape_expr"></a> [exporter\_scrape\_expr](#output\_exporter\_scrape\_expr) | Rendered PromQL for Connect exporter scrape alerts |
| <a name="output_task_failed_expr"></a> [task\_failed\_expr](#output\_task\_failed\_expr) | Rendered PromQL for task failed-state alerts |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
