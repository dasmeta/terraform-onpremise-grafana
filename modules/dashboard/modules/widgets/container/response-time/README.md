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
| <a name="input_account_id"></a> [account\_id](#input\_account\_id) | n/a | `string` | `null` | no |
| <a name="input_anomaly_detection"></a> [anomaly\_detection](#input\_anomaly\_detection) | Allow to enable anomaly detection on widget metrics | `bool` | `false` | no |
| <a name="input_anomaly_deviation"></a> [anomaly\_deviation](#input\_anomaly\_deviation) | Deviation of the anomaly band | `number` | `6` | no |
| <a name="input_balancer_name"></a> [balancer\_name](#input\_balancer\_name) | n/a | `string` | `null` | no |
| <a name="input_coordinates"></a> [coordinates](#input\_coordinates) | position | <pre>object({<br/>    x : number<br/>    y : number<br/>    width : number<br/>    height : number<br/>  })</pre> | n/a | yes |
| <a name="input_data_source"></a> [data\_source](#input\_data\_source) | The custom datasource for widget item | <pre>object({<br/>    uid  = optional(string, null)<br/>    type = optional(string, "prometheus")<br/>  })</pre> | n/a | yes |
| <a name="input_host"></a> [host](#input\_host) | n/a | `string` | `null` | no |
| <a name="input_period"></a> [period](#input\_period) | stats | `number` | `3` | no |
| <a name="input_problem"></a> [problem](#input\_problem) | The number which indicates the max timeout above which we have problem | `number` | `2` | no |
| <a name="input_region"></a> [region](#input\_region) | n/a | `string` | `""` | no |
| <a name="input_target_group_name"></a> [target\_group\_name](#input\_target\_group\_name) | n/a | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_data"></a> [data](#output\_data) | n/a |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
