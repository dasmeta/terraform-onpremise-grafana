variable "namespace" {
  type        = string
  description = "namespace for deployment of chart"
  default     = "monitoring"
}

variable "chart_version" {
  type        = string
  description = "loki chart version"
  default     = "2.10.2"
}

variable "release_name" {
  type    = string
  default = "loki"
}

variable "configs" {
  type = object({
    enable_test_pod = optional(bool, false)
    loki = optional(object({
      url            = optional(string, "")
      volume_enabled = optional(bool, true)
    }), {})
    promtail = optional(object({
      enabled              = optional(bool, true)
      log_level            = optional(string, "info")
      server_port          = optional(string, "3101")
      clients              = optional(list(string), [])
      log_format           = optional(string, "logfmt")
      extra_scrape_configs = optional(list(any), [])
      extra_label_configs  = optional(list(map(string)), [])
      ignored_containers   = optional(list(string), [])
      ignored_namespaces   = optional(list(string), [])
    }), {})
    fluentbit_enabled = optional(bool, false)
  })
  description = "Values to pass to loki helm chart"
  default     = {}
}
