variable "name" {
  type        = string
  description = "Service name"
}

variable "namespace" {
  type        = string
  description = "EKS namespace name"
}

variable "columns" {
  type        = number
  default     = 4
  description = "The number of widgets to place in each line"
}

variable "host" {
  type        = string
  default     = null
  description = "The service host name"
}

variable "prometheus_datasource_uid" {
  nullable    = false
  type        = string
  default     = "prometheus"
  description = "datasource uid for the metrics widgets"
}

variable "loki_datasource_uid" {
  nullable    = false
  type        = string
  default     = "loki"
  description = "datasource uid for the logs widgets"
}

variable "log_widgets" {
  type = object({
    enabled       = optional(bool, true)                         # whether log widgets are enabled, by default only size of total/error/warn logs will be shown
    show_logs     = optional(bool, false)                        # whether total/error/warn logs showing widgets are enabled, this widgets usually are heavy in terms of load on loki so we have them disabled by default
    parser        = optional(string, "logfmt")                   # parser to use to format logs before applying filter
    error_filter  = optional(string, "detected_level=\"error\"") # error logs widget filter
    warn_filter   = optional(string, "detected_level=\"warn\"")  # warn logs widget filter
    latest_filter = optional(string, "")                         # latest logs widget filter
    direction     = optional(string, "backward")                 # the direction search of log entries
    limit         = optional(number, 10)                         # count of items to fetch for each log widget
  })
  default     = {}
  description = "The logs widgets configs"
}

variable "disk_widgets" {
  type = object({
    enabled   = optional(bool, true)
    pvc_names = optional(list(string), [])
  })
  default     = {}
  description = "The configs allow to manage the volumes related widgets"
}
