variable "cluster_names" {
  type        = list(string)
  description = "List of MSK cluster names to monitor"
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
    labels      = optional(any, {})
    annotations = optional(any, {})
  })
  default = {}
}
