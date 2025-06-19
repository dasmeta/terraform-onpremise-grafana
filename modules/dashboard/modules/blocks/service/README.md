# service

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
| <a name="input_expr"></a> [expr](#input\_expr) | logql query used to query logs | `string` | `""` | no |
| <a name="input_host"></a> [host](#input\_host) | The service host name | `string` | `null` | no |
| <a name="input_loki_datasource_uid"></a> [loki\_datasource\_uid](#input\_loki\_datasource\_uid) | datasource uid for the logs widgets | `string` | `"loki"` | no |
| <a name="input_name"></a> [name](#input\_name) | Service name | `string` | n/a | yes |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | EKS namespace name | `string` | n/a | yes |
| <a name="input_prometheus_datasource_uid"></a> [prometheus\_datasource\_uid](#input\_prometheus\_datasource\_uid) | datasource uid for the metrics widgets | `string` | `"prometheus"` | no |
| <a name="input_region"></a> [region](#input\_region) | n/a | `string` | `""` | no |
| <a name="input_show_err_logs"></a> [show\_err\_logs](#input\_show\_err\_logs) | Wether to show the error and warning logs for the deployment | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_result"></a> [result](#output\_result) | description |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
