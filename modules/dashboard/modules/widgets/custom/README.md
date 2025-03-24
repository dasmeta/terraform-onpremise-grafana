# custom

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

No requirements.

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_base"></a> [base](#module\_base) | ../base | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_account_id"></a> [account\_id](#input\_account\_id) | n/a | `string` | `null` | no |
| <a name="input_anomaly_detection"></a> [anomaly\_detection](#input\_anomaly\_detection) | Enables anomaly detection on widget metrics | `bool` | `false` | no |
| <a name="input_anomaly_deviation"></a> [anomaly\_deviation](#input\_anomaly\_deviation) | Deviation of the anomaly band | `number` | `6` | no |
| <a name="input_coordinates"></a> [coordinates](#input\_coordinates) | position | <pre>object({<br/>    x : number<br/>    y : number<br/>    width : number<br/>    height : number<br/>  })</pre> | n/a | yes |
| <a name="input_data_source"></a> [data\_source](#input\_data\_source) | The custom datasource for widget item | <pre>object({<br/>    uid  = optional(string, null)<br/>    type = optional(string, "prometheus")<br/>  })</pre> | n/a | yes |
| <a name="input_decimals"></a> [decimals](#input\_decimals) | The decimals to enable on numbers | `number` | `0` | no |
| <a name="input_expressions"></a> [expressions](#input\_expressions) | Custom metric expressions over metrics, note that metrics have auto generated m1,m2,..., m{n} ids | <pre>list(object({<br/>    expression = string<br/>    label      = optional(string, null)<br/>    accountId  = optional(string, null)<br/>    visible    = optional(bool, null)<br/>    color      = optional(string, null)<br/>    yAxis      = optional(string, null)<br/>    region     = optional(string, null)<br/>  }))</pre> | `[]` | no |
| <a name="input_fillOpacity"></a> [fillOpacity](#input\_fillOpacity) | The fillOpacity value | `number` | `0` | no |
| <a name="input_metrics"></a> [metrics](#input\_metrics) | n/a | `any` | n/a | yes |
| <a name="input_period"></a> [period](#input\_period) | n/a | `number` | `3` | no |
| <a name="input_region"></a> [region](#input\_region) | n/a | `string` | `""` | no |
| <a name="input_stat"></a> [stat](#input\_stat) | n/a | `string` | `"Average"` | no |
| <a name="input_title"></a> [title](#input\_title) | n/a | `string` | n/a | yes |
| <a name="input_view"></a> [view](#input\_view) | The view for log insights and alarm widgets | `string` | `null` | no |
| <a name="input_yAxis"></a> [yAxis](#input\_yAxis) | Widget Item common yAxis option (applied only metric type widgets). | `any` | <pre>{<br/>  "left": {<br/>    "min": 0<br/>  }<br/>}</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_data"></a> [data](#output\_data) | n/a |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
