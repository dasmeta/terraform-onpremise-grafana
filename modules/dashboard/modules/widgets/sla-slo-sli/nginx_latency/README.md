# latency

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
| <a name="input_account_id"></a> [account\_id](#input\_account\_id) | n/a | `string` | `null` | no |
| <a name="input_balancer_name"></a> [balancer\_name](#input\_balancer\_name) | n/a | `string` | `null` | no |
| <a name="input_coordinates"></a> [coordinates](#input\_coordinates) | position | <pre>object({<br/>    x : number<br/>    y : number<br/>    width : number<br/>    height : number<br/>  })</pre> | n/a | yes |
| <a name="input_datasource_uid"></a> [datasource\_uid](#input\_datasource\_uid) | prometheus datasource type uid to use for widget | `string` | `"prometheus"` | no |
| <a name="input_histogram"></a> [histogram](#input\_histogram) | n/a | `bool` | `false` | no |
| <a name="input_period"></a> [period](#input\_period) | stats | `string` | `"3"` | no |
| <a name="input_region"></a> [region](#input\_region) | n/a | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_data"></a> [data](#output\_data) | n/a |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
