variable "name" {
  type        = string
  description = "The name of k8s deployment/service/app/container"
}

variable "namespace" {
  type        = string
  description = "The namespace of k8s service/app/container"
}

variable "datasource" {
  type        = string
  default     = "prometheus"
  description = "The grafana datasource id which will be used for alert"
}

variable "defaults" {
  type = object({
    enabled           = optional(bool, true)                 # whether by default block widget alerts are enabled, it allows to disable alert by default and enable for specific widget only
    workload_type     = optional(string, "deployment")       # the workload type of app setup, can be "daemonset", "deployment", "statefulset" and "cronjob"
    workload_suffix   = optional(string, "")                 # allows to filter workload or pod via {var.name}{var.defaults.workload_suffix} filtration, can be used for example in case we have flagger canary deployment to add "-primary" suffix to filter deployment
    workload_prefix   = optional(string, "")                 # allows to filter workload or pod via {var.defaults.workload_suffix}{var.name} filtration, can be used for example in case we have a deployment which name differs from container name with custom suffix like in nginx ingress container named "controller" and daemonset named "ingress-nginx-controller"
    labels            = optional(any, { "priority" : "P2" }) # the service level monitoring alarms generally are considered as P2 priority and desired to be sent to slack channel)
    pending_period    = optional(string, "1m")               # define for how long to wait to trigger alert if condition satisfied(how long should satisfied state last to fire)
    interval          = optional(string, "5m")               # the time interval to use to evaluate/aggregate/rate metric for comparison
    deviation         = optional(number, 10)                 # the deviation threshold to consider increase/decrease of metric as anomaly and fire alert, we use this now for network alert (in this case 10 means that the metric got increased x10 times withing provided interval)
    threshold_percent = optional(number, 99)                 # the percent threshold to use when triggering alerts on resources like cpu/memory
    no_data_state     = optional(string, "NoData")           # define how to handle if no data for query, by default it will fire alert with no data info
    group             = optional(string, null)               # grafana alert group name which used for grouping, if null the group name will be based on service name/namespace in format `Service {namespace}/{name}`
  })
  default     = {}
  description = "The general default values to use with alert rules"
}

variable "alerts" {
  type = object({
    replicas_no = optional(object({
      enabled        = optional(bool, null)                 # whether to have alert if no any replica/pod available
      pending_period = optional(string, "0s")               # define for how long to wait to trigger alert if condition satisfied(how long should satisfied state last to fire), if set `null` here it takes  defaults value
      labels         = optional(any, { "priority" : "P1" }) # define alert labels to filter in notification policies, this extends with override the defaults labels. we set here P1 priority as if there are no any pods the service is down
      no_data_state  = optional(string, null)               # define how to handle if no data for query, if set `null` here it takes  defaults value
      group          = optional(string, null)               # grafana alert group name which used for grouping, if set `null` here it takes  defaults value
      annotations    = optional(any, {})                    # define alert annotations to include in notifications
    }), {})
    replicas_min = optional(object({
      enabled        = optional(bool, null)   # whether to have alert on min replicas/pods, so that if there are no at least min count of pods/replicas it will trigger alert
      pending_period = optional(string, null) # define for how long to wait to trigger alert if condition satisfied(how long should satisfied state last to fire), if set `null` here it takes  defaults value
      threshold      = optional(number, null) # for manually set min replica count, if not specified it will automatically get this based on hpa min, recommended to not set this if hpa is enabled, but if prometheus horizontalpodautoscaler metrics are not enable there may be need to set this manually
      no_data_state  = optional(string, null) # define how to handle if no data for query, if set `null` here it takes  defaults value
      labels         = optional(any, {})      # define alert labels to filter in notification policies, if set `null` here it takes defaults labels.
      group          = optional(string, null) # grafana alert group name which used for grouping, if set `null` here it takes  defaults value
      annotations    = optional(any, {})      # define alert annotations to include in notifications
    }), {})
    replicas_max = optional(object({
      enabled        = optional(bool, null)   # whether to have alert on max replicas/pods, so that if it reached to max count of pods/replicas it will trigger alert
      pending_period = optional(string, null) # define for how long to wait to trigger alert if condition satisfied(how long should satisfied state last to fire), if set `null` here it takes  defaults value
      threshold      = optional(number, null) # for manually set max replica count, if not specified it will automatically get this based on hpa min, recommended to not set this if hpa is enabled, but if prometheus horizontalpodautoscaler metrics are not enable there may be need to set this manually
      no_data_state  = optional(string, null) # define how to handle if no data for query, if set `null` here it takes  defaults value
      labels         = optional(any, {})      # define alert labels to filter in notification policies, this extends with override the defaults labels
      group          = optional(string, null) # grafana alert group name which used for grouping, if set `null` here it takes  defaults value
      annotations    = optional(any, {})      # define alert annotations to include in notifications
    }), {})
    replicas_state = optional(object({
      enabled        = optional(bool, null)   # whether to have alert on Failed/Pending/Unknown status/phase replicas/pods, so that if it already long time there pods on those phase we get notified
      pending_period = optional(string, null) # define for how long to wait to trigger alert if condition satisfied(how long should satisfied state last to fire), if set `null` here it takes  defaults value
      threshold      = optional(number, 1)    # the min count of replicas/pods with Failed/Pending/Unknown status/phase to trigger alert
      no_data_state  = optional(string, null) # define how to handle if no data for query, if set `null` here it takes  defaults value
      labels         = optional(any, {})      # define alert labels to filter in notification policies, this extends with override the defaults labels
      group          = optional(string, null) # grafana alert group name which used for grouping, if set `null` here it takes  defaults value
      annotations    = optional(any, {})      # define alert annotations to include in notifications
    }), {})
    job_failed = optional(object({
      enabled        = optional(bool, false)  # whether to have alert on job/cronjob failed status, we have this alert disabled by default as it is only job/cronjob related
      pending_period = optional(string, null) # define for how long to wait to trigger alert if condition satisfied(how long should satisfied state last to fire), if set `null` here it takes  defaults value
      threshold      = optional(number, 1)    # the min count of failed jobs to trigger alert
      no_data_state  = optional(string, null) # define how to handle if no data for query, if set `null` here it takes  defaults value
      labels         = optional(any, {})      # define alert labels to filter in notification policies, this extends with override the defaults labels
      group          = optional(string, null) # grafana alert group name which used for grouping, if set `null` here it takes  defaults value
      annotations    = optional(any, {})      # define alert annotations to include in notifications
    }), {})
    restarts = optional(object({             # configure service pod/container restart based alert
      enabled       = optional(bool, null)   # whether the restart based alert is enabled
      interval      = optional(string, null) # the time interval used to evaluate/aggregate restart count, if set `null` here it takes  defaults value
      threshold     = optional(number, 3)    # the count of restarts that it will consider as read line to fire alert if exceeded
      no_data_state = optional(string, null) # define how to handle if no data for query, if set `null` here it takes  defaults value
      labels        = optional(any, {})      # define alert labels to filter in notification policies, this extends with override the defaults labels
      group         = optional(string, null) # grafana alert group name which used for grouping, if set `null` here it takes  defaults value
      annotations   = optional(any, {})      # define alert annotations to include in notifications
    }), {})
    network_in = optional(object({            # to configure network in/out traffic anomaly increase alerting
      enabled        = optional(bool, null)   # wether to create alert on network in/receive anomaly increase/decrease of traffic
      pending_period = optional(string, null) # define for how long to wait to trigger alert if condition satisfied(how long should satisfied state last to fire), if set `null` here it takes  defaults value
      interval       = optional(string, null) # the time interval to use to evaluate/aggregate/rate network avg traffic to compare with previous same interval value, if set `null` here it takes  defaults value
      deviation      = optional(number, null) # the threshold to consider increase/decrease of traffic as anomaly and fire alert (in this case 10 means that the traffic got increased x10 times withing provided interval)
      no_data_state  = optional(string, null) # define how to handle if no data for query, if set `null` here it takes  defaults value
      labels         = optional(any, {})      # define alert labels to filter in notification policies, this extends with override the defaults labels
      group          = optional(string, null) # grafana alert group name which used for grouping, if set `null` here it takes  defaults value
      annotations    = optional(any, {})      # define alert annotations to include in notifications
    }), {})
    network_out = optional(object({           # to configure network in/out traffic anomaly increase alerting
      enabled        = optional(bool, null)   # wether to create alert on network out/transmit anomaly increase/decrease of traffic
      pending_period = optional(string, null) # define for how long to wait to trigger alert if condition satisfied(how long should satisfied state last to fire), if set `null` here it takes  defaults value
      interval       = optional(string, null) # the time interval to use to evaluate/aggregate/rate network avg traffic to compare with previous same interval value, if set `null` here it takes  defaults value
      deviation      = optional(number, null) # the threshold to consider increase/decrease of traffic as anomaly and fire alert (in this case 10 means that the traffic got increased x10 times withing provided interval)
      no_data_state  = optional(string, null) # define how to handle if no data for query, if set `null` here it takes  defaults value
      labels         = optional(any, {})      # define alert labels to filter in notification policies, this extends with override the defaults labels
      group          = optional(string, null) # grafana alert group name which used for grouping, if set `null` here it takes  defaults value
      annotations    = optional(any, {})      # define alert annotations to include in notifications
    }), {})
    cpu = optional(object({                           # to configure cpu/memory overload based alerting
      enabled            = optional(bool, null)       # whether cpu high load based alerting is enabled
      pending_period     = optional(string, null)     # define for how long to wait to trigger alert if condition satisfied(how long should satisfied state last to fire), if set `null` here it takes  defaults value
      interval           = optional(string, null)     # the time interval to use to evaluate/aggregate/rate network avg traffic to compare with previous same interval value, if set `null` here it takes  defaults value
      threshold_percent  = optional(number, null)     # the read line percent to trigger alert of cpu/memory resource usage exceeded, if set `null` here it takes  defaults threshold_percent value
      threshold_resource = optional(string, "limits") # the read line limit metric to use, allowed values are "limits" or "requests"
      threshold          = optional(number, null)     # the read line limit in number of cores(0.256 means 256m) to calculate threshold_percent against, by default it uses deployment limit for this but in case no limit set this can be used to configure custom limit for alert
      no_data_state      = optional(string, null)     # define how to handle if no data for query, if set `null` here it takes  defaults value
      labels             = optional(any, {})          # define alert labels to filter in notification policies, this extends with override the defaults labels
      group              = optional(string, null)     # grafana alert group name which used for grouping, if set `null` here it takes  defaults value
      annotations        = optional(any, {})          # define alert annotations to include in notifications
    }), {})
    memory = optional(object({                        # to configure cpu/memory overload based alerting
      enabled            = optional(bool, null)       # whether cpu high load based alerting is enabled
      pending_period     = optional(string, null)     # define for how long to wait to trigger alert if condition satisfied(how long should satisfied state last to fire), if set `null` here it takes  defaults value
      threshold_percent  = optional(number, null)     # the read line percent to trigger alert of cpu/memory resource usage exceeded, if set `null` here it takes  defaults threshold_percent value
      threshold_resource = optional(string, "limits") # the read line limit metric to use, allowed values are "limits" or "requests"
      threshold          = optional(number, null)     # the read line limit in megabytes to calculate threshold_percent against, by default it uses deployment limit for this but in case no limit set this can be used to configure custom limit for alert
      no_data_state      = optional(string, null)     # define how to handle if no data for query, if set `null` here it takes  defaults value
      labels             = optional(any, {})          # define alert labels to filter in notification policies, this extends with override the defaults labels
      group              = optional(string, null)     # grafana alert group name which used for grouping, if set `null` here it takes  defaults value
      annotations        = optional(any, {})          # define alert annotations to include in notifications
    }), {})
    alert_format_params = optional(object({
      component    = optional(string, "")
      priority     = optional(string, "")
      owner        = optional(string, "")
      issue_phrase = optional(string, "")
      impact       = optional(string, "")
      runbook      = optional(string, "")
      provider     = optional(string, "")
      account      = optional(string, "")
      env          = optional(string, "")
      threshold    = optional(string, "")
      metric       = optional(string, "")
      resource     = optional(string, "")
      summary      = optional(string, "")
    }), {})
  })
  default     = {}
  description = "Alerts to enable on services/apps which have pods, if option set null it generally takes option value from var.defaults"
}
