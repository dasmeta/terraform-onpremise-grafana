variable "name" {
  type        = string
  default     = "controller"
  description = "The name of k8s deployment/service/app/container"
}

variable "namespace" {
  type        = string
  default     = "ingress-nginx"
  description = "The namespace of k8s service/app/container"
}

variable "datasource" {
  type        = string
  default     = "prometheus"
  description = "The grafana datasource id which will be used for alert"
}

variable "defaults" {
  type = object({
    enabled           = optional(bool, true)                     # whether by default block widget alerts are enabled, it allows to disable alert by default and enable for specific widget only
    workload_type     = optional(string, "daemonset")            # the workload type of app setup, can be "daemonset" and "deployment"
    workload_suffix   = optional(string, "")                     # allows to filter workload or pod via {var.name}{var.defaults.workload_suffix} filtration, can be used for example in case we have flagger canary deployment to add "-primary" suffix to filter deployment
    workload_prefix   = optional(string, "nginx-ingress-nginx-") # allows to filter workload or pod via {var.defaults.workload_suffix}{var.name} filtration, can be used for example in case we have a deployment which name differs from container name with custom suffix like in nginx ingress container named "controller" and daemonset named "ingress-nginx-controller"
    labels            = optional(any, { "priority" : "P2" })     # the service level monitoring alarms generally are considered as P2 priority and desired to be sent to slack channel)
    pending_period    = optional(string, "1m")                   # define for how long to wait to trigger alert if condition satisfied(how long should satisfied state last to fire)
    interval          = optional(string, "5m")                   # the time interval to use to evaluate/aggregate/rate metric for comparison
    threshold_percent = optional(number, 99)                     # the min percent threshold to use when triggering alerts on percent based expressions, higher values are good
    no_data_state     = optional(string, "NoData")               # define how to handle if no data for query, by default it will fire alert with no data info
    group             = optional(string, "1. nginx ingress")     # grafana alert group name which used for grouping
    metric_filter     = optional(string, " ")                    # allows to define custom metric filter, for example to exclude some host or path, we specially set `" "` as default value to not get coalesce() function failures
  })
  default     = {}
  description = "The general default values to use with alert rules"
}

variable "alerts" {
  type = object({
    latency = optional(object({               # configure nginx ingress latency alerts on all hosts/paths
      enabled        = optional(bool, null)   # whether to have alert on latency
      interval       = optional(string, null) # the time interval used to evaluate/aggregate restart count
      pending_period = optional(string, null) # define for how long to wait to trigger alert if condition satisfied(how long should satisfied state last to fire), if set `null` here it takes  defaults value
      threshold      = optional(number, 2)    # threshold seconds above which it will consider request too slow and will fire alert
      no_data_state  = optional(string, null) # define how to handle if no data for query
      labels         = optional(any, {})      # define alert labels to filter in notification policies, this extends with override the defaults labels
      group          = optional(string, null) # grafana alert group name which used for grouping
      metric_filter  = optional(string, "")   # allows to define custom metric filter, for example to exclude some host or path
    }), {})
    failed = optional(object({                   # configure nginx ingress 5xx|499 status code response alert on all hosts/paths
      enabled           = optional(bool, null)   # whether to have alert on failed(5xx|499) request
      interval          = optional(string, null) # the time interval used to evaluate/aggregate restart count
      pending_period    = optional(string, null) # define for how long to wait to trigger alert if condition satisfied(how long should satisfied state last to fire)
      threshold_percent = optional(number, null) # threshold min percent to fire the alert if exceeded(this is about non failed requests, so that high values are good), if set `null` here it takes defaults labels
      no_data_state     = optional(string, null) # define how to handle if no data for query
      labels            = optional(any, {})      # define alert labels to filter in notification policies, this extends with override the defaults labels
      group             = optional(string, null) # grafana alert group name which used for grouping
      metric_filter     = optional(string, "")   # allows to define custom metric filter, for example to exclude some host or path
    }), {})
    replicas_no = optional(object({
      enabled        = optional(bool, null)                 # whether to have alert if no any replica available
      pending_period = optional(string, "0s")               # define for how long to wait to trigger alert if condition satisfied(how long should satisfied state last to fire), if set `null` here it takes  defaults value
      labels         = optional(any, { "priority" : "P1" }) # define alert labels to filter in notification policies, this extends with override the defaults labels. we set here P1 priority as if there are no any pods the service is down
      no_data_state  = optional(string, null)               # define how to handle if no data for query, if set `null` here it takes  defaults value
      group          = optional(string, null)               # grafana alert group name which used for grouping, if set `null` here it takes  defaults value
    }), {})
    replicas_state = optional(object({
      enabled        = optional(bool, null)   # whether to have alert on Failed/Pending/Unknown status/phase replicas/pods, so that if it already long time there pods on those phase we get notified
      pending_period = optional(string, null) # define for how long to wait to trigger alert if condition satisfied(how long should satisfied state last to fire), if set `null` here it takes  defaults value
      threshold      = optional(number, 1)    # the min count of replicas/pods with Failed/Pending/Unknown status/phase to trigger alert
      no_data_state  = optional(string, null) # define how to handle if no data for query, if set `null` here it takes  defaults value
      labels         = optional(any, {})      # define alert labels to filter in notification policies, this extends with override the defaults labels
      group          = optional(string, null) # grafana alert group name which used for grouping, if set `null` here it takes  defaults value
    }), {})
    restarts = optional(object({             # configure service pod/container restart based alert
      enabled       = optional(bool, null)   # whether the restart based alert is enabled
      interval      = optional(string, null) # the time interval used to evaluate/aggregate restart count, if set `null` here it takes  defaults value
      threshold     = optional(number, 3)    # the count of restarts that it will consider as read line to fire alert if exceeded
      no_data_state = optional(string, null) # define how to handle if no data for query, if set `null` here it takes  defaults value
      labels        = optional(any, {})      # define alert labels to filter in notification policies, this extends with override the defaults labels
      group         = optional(string, null) # grafana alert group name which used for grouping, if set `null` here it takes  defaults value
    }), {})
    network_in = optional(object({            # to configure network in/out traffic anomaly increase alerting
      enabled        = optional(bool, null)   # wether to create alert on network in/receive anomaly increase/decrease of traffic
      pending_period = optional(string, null) # define for how long to wait to trigger alert if condition satisfied(how long should satisfied state last to fire), if set `null` here it takes  defaults value
      interval       = optional(string, null) # the time interval to use to evaluate/aggregate/rate network avg traffic to compare with previous same interval value, if set `null` here it takes  defaults value
      deviation      = optional(number, null) # the threshold to consider increase/decrease of traffic as anomaly and fire alert (in this case 10 means that the traffic got increased x10 times withing provided interval)
      no_data_state  = optional(string, null) # define how to handle if no data for query, if set `null` here it takes  defaults value
      labels         = optional(any, {})      # define alert labels to filter in notification policies, this extends with override the defaults labels
      group          = optional(string, null) # grafana alert group name which used for grouping, if set `null` here it takes  defaults value
    }), {})
    network_out = optional(object({           # to configure network in/out traffic anomaly increase alerting
      enabled        = optional(bool, null)   # wether to create alert on network out/transmit anomaly increase/decrease of traffic
      pending_period = optional(string, null) # define for how long to wait to trigger alert if condition satisfied(how long should satisfied state last to fire), if set `null` here it takes  defaults value
      interval       = optional(string, null) # the time interval to use to evaluate/aggregate/rate network avg traffic to compare with previous same interval value, if set `null` here it takes  defaults value
      deviation      = optional(number, null) # the threshold to consider increase/decrease of traffic as anomaly and fire alert (in this case 10 means that the traffic got increased x10 times withing provided interval)
      no_data_state  = optional(string, null) # define how to handle if no data for query, if set `null` here it takes  defaults value
      labels         = optional(any, {})      # define alert labels to filter in notification policies, this extends with override the defaults labels
      group          = optional(string, null) # grafana alert group name which used for grouping, if set `null` here it takes  defaults value
    }), {})
    cpu = optional(object({                             # to configure cpu/memory overload based alerting
      enabled            = optional(bool, null)         # whether cpu high load based alerting is enabled
      pending_period     = optional(string, null)       # define for how long to wait to trigger alert if condition satisfied(how long should satisfied state last to fire), if set `null` here it takes  defaults value
      interval           = optional(string, null)       # the time interval to use to evaluate/aggregate/rate network avg traffic to compare with previous same interval value, if set `null` here it takes  defaults value
      threshold_percent  = optional(number, null)       # the read line percent to trigger alert of cpu/memory resource usage exceeded, if set `null` here it takes  defaults threshold_percent value
      threshold_resource = optional(string, "requests") # the read line limit metric to use, allowed values are "limits" or "requests"
      threshold          = optional(number, null)       # the read line limit in number of cores(0.256 means 256m) to calculate threshold_percent against, by default it uses deployment limit for this but in case no limit set this can be used to configure custom limit for alert
      no_data_state      = optional(string, null)       # define how to handle if no data for query, if set `null` here it takes  defaults value
      labels             = optional(any, {})            # define alert labels to filter in notification policies, this extends with override the defaults labels
      group              = optional(string, null)       # grafana alert group name which used for grouping, if set `null` here it takes  defaults value
    }), {})
    memory = optional(object({                          # to configure cpu/memory overload based alerting
      enabled            = optional(bool, null)         # whether cpu high load based alerting is enabled
      pending_period     = optional(string, null)       # define for how long to wait to trigger alert if condition satisfied(how long should satisfied state last to fire), if set `null` here it takes  defaults value
      threshold_percent  = optional(number, null)       # the read line percent to trigger alert of cpu/memory resource usage exceeded, if set `null` here it takes  defaults threshold_percent value
      threshold_resource = optional(string, "requests") # the read line limit metric to use, allowed values are "limits" or "requests"
      threshold          = optional(number, null)       # the read line limit in megabytes to calculate threshold_percent against, by default it uses deployment limit for this but in case no limit set this can be used to configure custom limit for alert
      no_data_state      = optional(string, null)       # define how to handle if no data for query, if set `null` here it takes  defaults value
      labels             = optional(any, {})            # define alert labels to filter in notification policies, this extends with override the defaults labels
      group              = optional(string, null)       # grafana alert group name which used for grouping, if set `null` here it takes  defaults value
    }), {})
  })
  default     = {}
  description = "Alerts to enable on nginx ingress block widgets, if option set null it generally takes option value from var.defaults"
}
