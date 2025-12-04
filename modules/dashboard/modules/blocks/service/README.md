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
| <a name="input_columns"></a> [columns](#input\_columns) | The number of widgets to place in each line | `number` | `4` | no |
| <a name="input_disk_widgets"></a> [disk\_widgets](#input\_disk\_widgets) | The configs allow to manage the volumes related widgets | <pre>object({<br/>    enabled   = optional(bool, true)<br/>    pvc_names = optional(list(string), [])<br/>  })</pre> | `{}` | no |
| <a name="input_host"></a> [host](#input\_host) | The service host name | `string` | `null` | no |
| <a name="input_log_widgets"></a> [log\_widgets](#input\_log\_widgets) | The logs widgets configs | <pre>object({<br/>    enabled       = optional(bool, true)                         # whether log widgets are enabled, by default only size of total/error/warn logs will be shown<br/>    show_logs     = optional(bool, false)                        # whether total/error/warn logs showing widgets are enabled, this widgets usually are heavy in terms of load on loki so we have them disabled by default<br/>    parser        = optional(string, "logfmt")                   # parser to use to format logs before applying filter<br/>    error_filter  = optional(string, "detected_level=\"error\"") # error logs widget filter<br/>    warn_filter   = optional(string, "detected_level=\"warn\"")  # warn logs widget filter<br/>    latest_filter = optional(string, "")                         # latest logs widget filter<br/>    direction     = optional(string, "backward")                 # the direction search of log entries<br/>    limit         = optional(number, 10)                         # count of items to fetch for each log widget<br/>  })</pre> | `{}` | no |
| <a name="input_loki_datasource_uid"></a> [loki\_datasource\_uid](#input\_loki\_datasource\_uid) | datasource uid for the logs widgets | `string` | `"loki"` | no |
| <a name="input_name"></a> [name](#input\_name) | Service name | `string` | n/a | yes |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | EKS namespace name | `string` | n/a | yes |
| <a name="input_period"></a> [period](#input\_period) | n/a | `string` | `"$__rate_interval"` | no |
| <a name="input_period_loki"></a> [period\_loki](#input\_period\_loki) | n/a | `string` | `"$__interval"` | no |
| <a name="input_prometheus_datasource_uid"></a> [prometheus\_datasource\_uid](#input\_prometheus\_datasource\_uid) | datasource uid for the metrics widgets | `string` | `"prometheus"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_result"></a> [result](#output\_result) | description |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
