variable "datasource" {
  type        = string
  default     = "prometheus"
  description = "The grafana datasource id which will be used for alert"
}

variable "defaults" {
  type = object({
    enabled           = optional(bool, true)                     # whether by default block widget alerts are enabled, it allows to disable alert by default and enable for specific widget only
    labels            = optional(any, { "priority" : "P1" })     # the service level monitoring alarms generally are considered as P2 priority and desired to be sent to slack channel)
    pending_period    = optional(string, "1m")                   # define for how long to wait to trigger alert if condition satisfied(how long should satisfied state last to fire)
    interval          = optional(string, "5m")                   # the time interval to use to evaluate/aggregate/rate metric for comparison
    threshold_percent = optional(number, 99)                     # the min percent threshold to use in when triggering alerts, higher values are good
    no_data_state     = optional(string, "NoData")               # define how to handle if no data for query, by default it will fire alert with no data info
    exec_err_state    = optional(string, "Error")                # define how to handle if query execution error, by default it will fire alert with error info
    group             = optional(string, "0. sla nginx ingress") # grafana alert group name which used for grouping
    metric_filter     = optional(string, " ")                    # allows to define custom metric filter, for example to exclude some host or path, we specially set `" "` as default value to not get coalesce() function failures
  })
  default     = {}
  description = "The general default values to use with alert rules"
}

variable "alerts" {
  type = object({
    latency = optional(object({               # configure latency on SLA for nginx ingress
      enabled        = optional(bool, null)   # whether to have alert on latency
      interval       = optional(string, null) # the time interval used to evaluate/aggregate restart count, if set `null` here it takes  defaults value
      pending_period = optional(string, null) # define for how long to wait to trigger alert if condition satisfied(how long should satisfied state last to fire), if set `null` here it takes  defaults value
      threshold      = optional(number, 2)    # threshold seconds above which it will consider request too slow and will fire alert
      no_data_state  = optional(string, null) # define how to handle if no data for query, if set `null` here it takes  defaults value
      exec_err_state = optional(string, null) # define how to handle if query execution error, if set `null` here it takes  defaults value
      labels         = optional(any, {})      # define alert labels to filter in notification policies, this extends with override the defaults labels
      annotations    = optional(any, {})      # define alert annotations to filter in notification policies, this extends with override the defaults annotations
      group          = optional(string, null) # grafana alert group name which used for grouping, if set `null` here it takes  defaults value
      metric_filter  = optional(string, "")   # allows to define custom metric filter, for example to exclude some host or path
    }), {})
    availability = optional(object({          # configure availability for nginx ingress
      enabled        = optional(bool, null)   # whether to have alert on availability decrease
      interval       = optional(string, null) # the time interval used to evaluate/aggregate restart count, if set `null` here it takes  defaults value
      pending_period = optional(string, null) # define for how long to wait to trigger alert if condition satisfied(how long should satisfied state last to fire), if set `null` here it takes  defaults value
      threshold      = optional(number, null) # threshold max percent to fire the alert if exceeded, if set `null` here it takes defaults labels
      no_data_state  = optional(string, null) # define how to handle if no data for query, if set `null` here it takes  defaults value
      exec_err_state = optional(string, null) # define how to handle if query execution error, if set `null` here it takes  defaults value
      labels         = optional(any, {})      # define alert labels to filter in notification policies, this extends with override the defaults labels
      annotations    = optional(any, {})      # define alert annotations to filter in notification policies, this extends with override the defaults annotations
      group          = optional(string, null) # grafana alert group name which used for grouping, if set `null` here it takes  defaults value
      metric_filter  = optional(string, "")   # allows to define custom metric filter, for example to exclude some host or path
    }), {})
  })
  default     = {}
  description = "Alerts to enable on block/sla for nginx, if option set null it generally takes option value from var.defaults"
}
