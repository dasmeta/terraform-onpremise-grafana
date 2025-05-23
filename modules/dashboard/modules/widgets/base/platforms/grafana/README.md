# grafana

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
| <a name="input_alarms"></a> [alarms](#input\_alarms) | The list of alarm\_arns used for properties->alarms option in alarm widgets | `list(string)` | `null` | no |
| <a name="input_annotations"></a> [annotations](#input\_annotations) | The annotations option for alarm widgets | `any` | `null` | no |
| <a name="input_cloudwatch_targets"></a> [cloudwatch\_targets](#input\_cloudwatch\_targets) | Target section of the cloudwatch based widget | <pre>list(object({<br/>    query_mode  = optional(string, "Metrics") # Logs or Metrics<br/>    region      = optional(string, "eu-central-1")<br/>    namespace   = optional(string, "AWS/EC2")<br/>    metric_name = optional(string, "CPUUtilization")<br/>    dimensions  = optional(map(string), {})<br/>    statistic   = optional(string, "Average")<br/>    hide        = optional(bool, false)<br/>    period      = optional(string, "300")<br/>    refId       = optional(string, "A")<br/>    label       = optional(string, "")<br/>  }))</pre> | `[]` | no |
| <a name="input_color_mode"></a> [color\_mode](#input\_color\_mode) | Color mode used for a widget | `string` | `"palette-classic"` | no |
| <a name="input_coordinates"></a> [coordinates](#input\_coordinates) | n/a | <pre>object({<br/>    x : number<br/>    y : number<br/>    width : number<br/>    height : number<br/>  })</pre> | n/a | yes |
| <a name="input_data_source"></a> [data\_source](#input\_data\_source) | The custom datasource for widget item | <pre>object({<br/>    uid  = optional(string, null)<br/>    type = optional(string, "prometheus")<br/>  })</pre> | n/a | yes |
| <a name="input_decimals"></a> [decimals](#input\_decimals) | The decimals to enable on numbers | `number` | `0` | no |
| <a name="input_defaults"></a> [defaults](#input\_defaults) | Default values that will be passed to all metrics. | `any` | `{}` | no |
| <a name="input_description"></a> [description](#input\_description) | Description for the widget | `string` | `""` | no |
| <a name="input_fillOpacity"></a> [fillOpacity](#input\_fillOpacity) | The fillOpacity value | `number` | `0` | no |
| <a name="input_loki_targets"></a> [loki\_targets](#input\_loki\_targets) | Target section of Loki based widget | <pre>list(object({<br/>    expr          = string<br/>    format        = optional(string, "time_series")<br/>    refId         = optional(string, "A")<br/>    legend_format = optional(string, "Errors ({{instance}})")<br/>    queryType     = optional(string, "range")<br/>    hide          = optional(bool, false)<br/>  }))</pre> | `[]` | no |
| <a name="input_metrics"></a> [metrics](#input\_metrics) | Metrics to be displayed on the widget. | `any` | `[]` | no |
| <a name="input_name"></a> [name](#input\_name) | n/a | `string` | n/a | yes |
| <a name="input_options"></a> [options](#input\_options) | Configuration options for widget legend and tooltip. | <pre>object({<br/>    legend = object({<br/>      calcs       = optional(list(string), [])<br/>      displayMode = optional(string, "list")<br/>      placement   = optional(string, "bottom")<br/>      show_legend = optional(bool, true)<br/>    })<br/>    tooltip = optional(object({<br/>      mode = optional(string, "single")<br/>      sort = optional(string, "none")<br/>    }), {})<br/>  })</pre> | <pre>{<br/>  "legend": {<br/>    "calcs": [],<br/>    "displayMode": "list",<br/>    "placement": "bottom",<br/>    "show_legend": true<br/>  },<br/>  "tooltip": {<br/>    "mode": "single",<br/>    "sort": "none"<br/>  }<br/>}</pre> | no |
| <a name="input_period"></a> [period](#input\_period) | n/a | `string` | `"3"` | no |
| <a name="input_query"></a> [query](#input\_query) | The PromQL query to use for the chart | <pre>list(object({<br/>    datasource = object({<br/>      uid  = optional(string, "__expr__")<br/>      type = optional(string, "__expr__")<br/>      name = optional(string, "Expression")<br/>    })<br/>    expression = optional(string, "")<br/>    refId      = optional(string, "")<br/>    querymode  = optional(string, "")<br/>    type       = optional(string, "math")<br/>    hide       = optional(bool, false)<br/>  }))</pre> | `[]` | no |
| <a name="input_region"></a> [region](#input\_region) | n/a | `string` | `""` | no |
| <a name="input_sources"></a> [sources](#input\_sources) | Log groups list for Logs Insights query | `list(string)` | `[]` | no |
| <a name="input_stat"></a> [stat](#input\_stat) | n/a | `string` | `"Average"` | no |
| <a name="input_targets"></a> [targets](#input\_targets) | Custom targets to use | `any` | `null` | no |
| <a name="input_tempo_targets"></a> [tempo\_targets](#input\_tempo\_targets) | Target section of tempo based widget | <pre>list(object({<br/>    filters = optional(list(any), [])<br/>    limit   = optional(number, 20)<br/>    query   = string<br/>  }))</pre> | `[]` | no |
| <a name="input_thresholds"></a> [thresholds](#input\_thresholds) | Thresholds defined for a widget | <pre>object({<br/>    mode = string<br/>    steps = list(object({<br/>      color = string<br/>      value = number<br/>    }))<br/>  })</pre> | <pre>{<br/>  "mode": "absolute",<br/>  "steps": [<br/>    {<br/>      "color": "green",<br/>      "value": null<br/>    },<br/>    {<br/>      "color": "red",<br/>      "value": 80<br/>    }<br/>  ]<br/>}</pre> | no |
| <a name="input_type"></a> [type](#input\_type) | The type of widget to be prepared | `string` | `"metric"` | no |
| <a name="input_unit"></a> [unit](#input\_unit) | Unit used for widget metric | `string` | `""` | no |
| <a name="input_view"></a> [view](#input\_view) | The view for log insights and alarm widgets | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_data"></a> [data](#output\_data) | n/a |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
