# response-time

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
| <a name="input_acceptable"></a> [acceptable](#input\_acceptable) | The number which indicates the acceptable timeout | `number` | `1` | no |
| <a name="input_by_host"></a> [by\_host](#input\_by\_host) | n/a | `bool` | `false` | no |
| <a name="input_coordinates"></a> [coordinates](#input\_coordinates) | position | <pre>object({<br/>    x : number<br/>    y : number<br/>    width : number<br/>    height : number<br/>  })</pre> | n/a | yes |
| <a name="input_datasource_type"></a> [datasource\_type](#input\_datasource\_type) | n/a | `string` | `"prometheus"` | no |
| <a name="input_datasource_uid"></a> [datasource\_uid](#input\_datasource\_uid) | n/a | `string` | `"prometheus"` | no |
| <a name="input_filter"></a> [filter](#input\_filter) | Allows to define additional filter on metric | `string` | `""` | no |
| <a name="input_ingress_type"></a> [ingress\_type](#input\_ingress\_type) | n/a | `string` | `"nginx"` | no |
| <a name="input_period"></a> [period](#input\_period) | stats | `string` | `"$__rate_interval"` | no |
| <a name="input_problem"></a> [problem](#input\_problem) | The number which indicates the max timeout above which we have problem | `number` | `2` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_data"></a> [data](#output\_data) | n/a |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
