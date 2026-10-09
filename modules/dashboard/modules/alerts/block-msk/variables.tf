variable "cluster_names" {
  type        = list(string)
  description = "List of MSK cluster names to monitor"
}

variable "consumer_groups" {
  type        = list(string)
  description = "Consumer groups used for DEFAULT MaxOffsetLag alerts"
  default     = []
}

variable "topics" {
  type        = list(string)
  description = "Optional topics used for DEFAULT MaxOffsetLag alert dimensions"
  default     = []
}

variable "lag_threshold" {
  type        = number
  description = "Default MaxOffsetLag threshold when alerts.consumer_lag.threshold is unset"
  default     = 10000
}

variable "region" {
  type        = string
  description = "AWS region for CloudWatch MSK metrics"
}

variable "datasource" {
  type        = string
  description = "CloudWatch datasource UID"
  default     = "cloudwatch"
}

variable "defaults" {
  type = object({
    enabled        = optional(bool, true)
    group          = optional(string, null)
    pending_period = optional(string, "5m")
    labels         = optional(any, {})
    no_data_state  = optional(string, "NoData")
    exec_err_state = optional(string, "Error")
  })
  default = {}
}

variable "alerts" {
  type = object({
    enabled = optional(bool, false)
    offline_partitions = optional(object({
      enabled        = optional(bool, true)
      threshold      = optional(number, 0)
      pending_period = optional(string, null)
      labels         = optional(any, {})
      annotations    = optional(any, {})
      group          = optional(string, null)
      no_data_state  = optional(string, null)
      exec_err_state = optional(string, null)
    }), {})
    consumer_lag = optional(object({
      enabled        = optional(bool, true)
      threshold      = optional(number, null)
      pending_period = optional(string, "15m")
      labels         = optional(any, {})
      annotations    = optional(any, {})
      group          = optional(string, null)
      no_data_state  = optional(string, null)
      exec_err_state = optional(string, null)
    }), {})
    labels      = optional(any, {})
    annotations = optional(any, {})
  })
  default = {}
}
