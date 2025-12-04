# replicas

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
| <a name="input_coordinates"></a> [coordinates](#input\_coordinates) | position | <pre>object({<br/>    x : number<br/>    y : number<br/>    width : number<br/>    height : number<br/>  })</pre> | n/a | yes |
| <a name="input_datasource_uid"></a> [datasource\_uid](#input\_datasource\_uid) | The custom datasource for widget item | `string` | `"loki"` | no |
| <a name="input_deployment"></a> [deployment](#input\_deployment) | n/a | `string` | n/a | yes |
| <a name="input_direction"></a> [direction](#input\_direction) | The direction search of log entries | `string` | `"backward"` | no |
| <a name="input_expr"></a> [expr](#input\_expr) | LogQl expression to get the logs | `string` | `""` | no |
| <a name="input_filter"></a> [filter](#input\_filter) | The logs filter expression | `string` | `"detected_level=\"warn\""` | no |
| <a name="input_limit"></a> [limit](#input\_limit) | The number of log items to fetch | `number` | `10` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | n/a | `string` | `"default"` | no |
| <a name="input_parser"></a> [parser](#input\_parser) | The logs parser to use before filtration | `string` | `"logfmt"` | no |
| <a name="input_period"></a> [period](#input\_period) | stats | `string` | `"3"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_data"></a> [data](#output\_data) | n/a |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
