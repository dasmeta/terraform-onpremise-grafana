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
| <a name="input_cloudwatch_targets"></a> [cloudwatch\_targets](#input\_cloudwatch\_targets) | Target section of the cloudwatch based widget | <pre>list(object({<br/>    datasource_uid = optional(string, "cloudwatch")<br/>    query_mode     = optional(string, "Metrics") # Logs or Metrics<br/>    region         = optional(string, "eu-central-1")<br/>    namespace      = optional(string, "AWS/EC2")<br/>    metric_name    = optional(string, "CPUUtilization")<br/>    dimensions     = optional(map(string), {})<br/>    statistic      = optional(string, "Average")<br/>    period         = optional(number, 300)<br/>    refId          = optional(string, "A")<br/>    id             = optional(string, "")<br/>    hide           = optional(bool, false)<br/>    widget_name    = optional(string, "widget_cloudwatch")<br/>  }))</pre> | `[]` | no |
| <a name="input_coordinates"></a> [coordinates](#input\_coordinates) | position | <pre>object({<br/>    x : number<br/>    y : number<br/>    width : number<br/>    height : number<br/>  })</pre> | n/a | yes |
| <a name="input_data_source"></a> [data\_source](#input\_data\_source) | The custom datasource for widget item | <pre>object({<br/>    uid  = optional(string, null)<br/>    type = optional(string, "prometheus")<br/>  })</pre> | n/a | yes |
| <a name="input_decimals"></a> [decimals](#input\_decimals) | The decimals to enable on numbers | `number` | `0` | no |
| <a name="input_expressions"></a> [expressions](#input\_expressions) | Custom metric expressions over metrics, note that metrics have auto generated m1,m2,..., m{n} ids | <pre>list(object({<br/>    expression = string<br/>    label      = optional(string, null)<br/>    accountId  = optional(string, null)<br/>    visible    = optional(bool, null)<br/>    color      = optional(string, null)<br/>    yAxis      = optional(string, null)<br/>    region     = optional(string, null)<br/>  }))</pre> | `[]` | no |
| <a name="input_fillOpacity"></a> [fillOpacity](#input\_fillOpacity) | The fillOpacity value | `number` | `0` | no |
| <a name="input_loki_targets"></a> [loki\_targets](#input\_loki\_targets) | Target section of Loki based widget | <pre>list(object({<br/>    expr          = string<br/>    format        = optional(string, "time_series")<br/>    refId         = optional(string, "A")<br/>    legend_format = optional(string, "Errors ({{instance}})")<br/>    queryType     = optional(string, "range")<br/>    hide          = optional(bool, false)<br/>  }))</pre> | `[]` | no |
| <a name="input_metrics"></a> [metrics](#input\_metrics) | n/a | `any` | n/a | yes |
| <a name="input_period"></a> [period](#input\_period) | n/a | `number` | `3` | no |
| <a name="input_region"></a> [region](#input\_region) | n/a | `string` | `""` | no |
| <a name="input_stat"></a> [stat](#input\_stat) | n/a | `string` | `"Average"` | no |
| <a name="input_tempo_targets"></a> [tempo\_targets](#input\_tempo\_targets) | Target section of tempo based widget | <pre>list(object({<br/>    filters = optional(list(any), [])<br/>    limit   = optional(number, 20)<br/>    query   = string<br/>  }))</pre> | `[]` | no |
| <a name="input_title"></a> [title](#input\_title) | n/a | `string` | n/a | yes |
| <a name="input_view"></a> [view](#input\_view) | The view for log insights and alarm widgets | `string` | `null` | no |
| <a name="input_yAxis"></a> [yAxis](#input\_yAxis) | Widget Item common yAxis option (applied only metric type widgets). | `any` | <pre>{<br/>  "left": {<br/>    "min": 0<br/>  }<br/>}</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_data"></a> [data](#output\_data) | n/a |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
