## terraform module prepares sla related alert rules based on nginx ingress k8s prometheus metrics
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_grafana"></a> [grafana](#requirement\_grafana) | >= 4.0.0 |

## Providers

No providers.

## Modules

No modules.

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_alerts"></a> [alerts](#input\_alerts) | Alerts to enable on block/sla for nginx, if option set null it generally takes option value from var.defaults | <pre>object({<br/>    latency = optional(object({               # configure latency on SLA for nginx ingress<br/>      enabled        = optional(bool, null)   # whether to have alert on latency<br/>      interval       = optional(string, null) # the time interval used to evaluate/aggregate restart count, if set `null` here it takes  defaults value<br/>      pending_period = optional(string, null) # define for how long to wait to trigger alert if condition satisfied(how long should satisfied state last to fire), if set `null` here it takes  defaults value<br/>      threshold      = optional(number, 2)    # threshold seconds above which it will consider request too slow and will fire alert<br/>      no_data_state  = optional(string, null) # define how to handle if no data for query, if set `null` here it takes  defaults value<br/>      exec_err_state = optional(string, null) # define how to handle if query execution error, if set `null` here it takes  defaults value<br/>      labels         = optional(any, {})      # define alert labels to filter in notification policies, this extends with override the defaults labels<br/>      annotations    = optional(any, {})      # define alert annotations to filter in notification policies, this extends with override the defaults annotations<br/>      group          = optional(string, null) # grafana alert group name which used for grouping, if set `null` here it takes  defaults value<br/>      metric_filter  = optional(string, "")   # allows to define custom metric filter, for example to exclude some host or path<br/>    }), {})<br/>    availability = optional(object({          # configure availability for nginx ingress<br/>      enabled        = optional(bool, null)   # whether to have alert on availability decrease<br/>      interval       = optional(string, null) # the time interval used to evaluate/aggregate restart count, if set `null` here it takes  defaults value<br/>      pending_period = optional(string, null) # define for how long to wait to trigger alert if condition satisfied(how long should satisfied state last to fire), if set `null` here it takes  defaults value<br/>      threshold      = optional(number, null) # threshold max percent to fire the alert if exceeded, if set `null` here it takes defaults labels<br/>      no_data_state  = optional(string, null) # define how to handle if no data for query, if set `null` here it takes  defaults value<br/>      exec_err_state = optional(string, null) # define how to handle if query execution error, if set `null` here it takes  defaults value<br/>      labels         = optional(any, {})      # define alert labels to filter in notification policies, this extends with override the defaults labels<br/>      annotations    = optional(any, {})      # define alert annotations to filter in notification policies, this extends with override the defaults annotations<br/>      group          = optional(string, null) # grafana alert group name which used for grouping, if set `null` here it takes  defaults value<br/>      metric_filter  = optional(string, "")   # allows to define custom metric filter, for example to exclude some host or path<br/>    }), {})<br/>  })</pre> | `{}` | no |
| <a name="input_datasource"></a> [datasource](#input\_datasource) | The grafana datasource id which will be used for alert | `string` | `"prometheus"` | no |
| <a name="input_defaults"></a> [defaults](#input\_defaults) | The general default values to use with alert rules | <pre>object({<br/>    enabled           = optional(bool, true)                     # whether by default block widget alerts are enabled, it allows to disable alert by default and enable for specific widget only<br/>    labels            = optional(any, { "priority" : "P1" })     # the service level monitoring alarms generally are considered as P2 priority and desired to be sent to slack channel)<br/>    pending_period    = optional(string, "1m")                   # define for how long to wait to trigger alert if condition satisfied(how long should satisfied state last to fire)<br/>    interval          = optional(string, "5m")                   # the time interval to use to evaluate/aggregate/rate metric for comparison<br/>    threshold_percent = optional(number, 99)                     # the min percent threshold to use in when triggering alerts, higher values are good<br/>    no_data_state     = optional(string, "NoData")               # define how to handle if no data for query, by default it will fire alert with no data info<br/>    exec_err_state    = optional(string, "Error")                # define how to handle if query execution error, by default it will fire alert with error info<br/>    group             = optional(string, "0. sla nginx ingress") # grafana alert group name which used for grouping<br/>    metric_filter     = optional(string, " ")                    # allows to define custom metric filter, for example to exclude some host or path, we specially set `" "` as default value to not get coalesce() function failures<br/>  })</pre> | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_alert_rules"></a> [alert\_rules](#output\_alert\_rules) | The generated alert rules |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
