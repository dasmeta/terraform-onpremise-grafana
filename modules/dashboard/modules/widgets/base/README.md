# base

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

No requirements.

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_base_grafana"></a> [base\_grafana](#module\_base\_grafana) | ./platforms/grafana | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_alarms"></a> [alarms](#input\_alarms) | The list of alarm\_arns used for properties->alarms option in alarm widgets | `list(string)` | `null` | no |
| <a name="input_annotations"></a> [annotations](#input\_annotations) | The annotations option for alarm widgets | `any` | `null` | no |
| <a name="input_anomaly_detection"></a> [anomaly\_detection](#input\_anomaly\_detection) | Allow to enable anomaly detection on widget metrics | `bool` | `false` | no |
| <a name="input_anomaly_deviation"></a> [anomaly\_deviation](#input\_anomaly\_deviation) | Deviation of the anomaly band | `number` | `6` | no |
| <a name="input_color_mode"></a> [color\_mode](#input\_color\_mode) | Color mode used for a widget | `string` | `"palette-classic"` | no |
| <a name="input_coordinates"></a> [coordinates](#input\_coordinates) | n/a | <pre>object({<br/>    x : number<br/>    y : number<br/>    width : number<br/>    height : number<br/>  })</pre> | n/a | yes |
| <a name="input_data_source"></a> [data\_source](#input\_data\_source) | The custom datasource for widget item | <pre>object({<br/>    uid  = optional(string, null)<br/>    type = optional(string, "prometheus")<br/>  })</pre> | n/a | yes |
| <a name="input_decimals"></a> [decimals](#input\_decimals) | The decimals to enable on numbers | `number` | `0` | no |
| <a name="input_defaults"></a> [defaults](#input\_defaults) | Default values that will be passed to all metrics. | `any` | `{}` | no |
| <a name="input_description"></a> [description](#input\_description) | Description for the widget | `string` | `""` | no |
| <a name="input_end"></a> [end](#input\_end) | end of widget | `string` | `null` | no |
| <a name="input_expressions"></a> [expressions](#input\_expressions) | Custom metric expressions over metrics, note that metrics have auto generated m1,m2,..., m{n} ids | <pre>list(object({<br/>    expression = string<br/>    label      = optional(string, null)<br/>    accountId  = optional(string, null)<br/>    visible    = optional(bool, null)<br/>    color      = optional(string, null)<br/>    yAxis      = optional(string, null)<br/>    region     = optional(string, null)<br/>    id         = optional(string, null)<br/>  }))</pre> | `[]` | no |
| <a name="input_fillOpacity"></a> [fillOpacity](#input\_fillOpacity) | The fillOpacity value | `number` | `0` | no |
| <a name="input_metrics"></a> [metrics](#input\_metrics) | Metrics to be displayed on the widget. | `any` | `[]` | no |
| <a name="input_name"></a> [name](#input\_name) | n/a | `string` | n/a | yes |
| <a name="input_options"></a> [options](#input\_options) | Configuration options for widget legend and tooltip. | <pre>object({<br/>    legend = object({<br/>      calcs       = optional(list(string), [])<br/>      displayMode = optional(string, "list")<br/>      placement   = optional(string, "bottom")<br/>      show_legend = optional(bool, true)<br/>    })<br/>    tooltip = optional(object({<br/>      mode = optional(string, "single")<br/>      sort = optional(string, "none")<br/>    }), {})<br/>  })</pre> | <pre>{<br/>  "legend": {<br/>    "calcs": [],<br/>    "displayMode": "list",<br/>    "placement": "bottom",<br/>    "show_legend": true<br/>  },<br/>  "tooltip": {<br/>    "mode": "single",<br/>    "sort": "none"<br/>  }<br/>}</pre> | no |
| <a name="input_period"></a> [period](#input\_period) | n/a | `number` | `3` | no |
| <a name="input_properties_type"></a> [properties\_type](#input\_properties\_type) | The properties->type option for alarm widgets | `string` | `null` | no |
| <a name="input_query"></a> [query](#input\_query) | The Logs Insights complete build query without sources and other options(in case of metric) query | `string` | `null` | no |
| <a name="input_region"></a> [region](#input\_region) | n/a | `string` | `""` | no |
| <a name="input_setPeriodToTimeRange"></a> [setPeriodToTimeRange](#input\_setPeriodToTimeRange) | setPeriodToTimeRange of widget | `bool` | `null` | no |
| <a name="input_singleValueFullPrecision"></a> [singleValueFullPrecision](#input\_singleValueFullPrecision) | singleValueFullPrecision of widget | `bool` | `null` | no |
| <a name="input_sources"></a> [sources](#input\_sources) | Log groups list for Logs Insights query | `list(string)` | `[]` | no |
| <a name="input_sparkline"></a> [sparkline](#input\_sparkline) | sparkline of widget | `bool` | `null` | no |
| <a name="input_stacked"></a> [stacked](#input\_stacked) | The stacked option for log insights and alarm widgets | `bool` | `null` | no |
| <a name="input_start"></a> [start](#input\_start) | start of widget | `string` | `null` | no |
| <a name="input_stat"></a> [stat](#input\_stat) | n/a | `string` | `"Average"` | no |
| <a name="input_thresholds"></a> [thresholds](#input\_thresholds) | Thresholds defined for a widget | <pre>object({<br/>    mode = string<br/>    steps = list(object({<br/>      color = string<br/>      value = number<br/>    }))<br/>  })</pre> | <pre>{<br/>  "mode": "absolute",<br/>  "steps": [<br/>    {<br/>      "color": "green",<br/>      "value": null<br/>    },<br/>    {<br/>      "color": "red",<br/>      "value": 80<br/>    }<br/>  ]<br/>}</pre> | no |
| <a name="input_trend"></a> [trend](#input\_trend) | trend of widget | `bool` | `null` | no |
| <a name="input_type"></a> [type](#input\_type) | The type of widget to be prepared | `string` | `"metric"` | no |
| <a name="input_unit"></a> [unit](#input\_unit) | Unit used for widget metric | `string` | `""` | no |
| <a name="input_view"></a> [view](#input\_view) | The view for log insights and alarm widgets | `string` | `null` | no |
| <a name="input_yAxis"></a> [yAxis](#input\_yAxis) | Widget Item common yAxis option (applied only metric type widgets). | `any` | <pre>{<br/>  "left": {}<br/>}</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_data"></a> [data](#output\_data) | n/a |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
