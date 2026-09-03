variable "namespace" {
  type        = string
  description = "namespace for tempo deployment"
  default     = "monitoring"
}

variable "create_namespace" {
  type        = bool
  description = "Whether create namespace if not exist"
  default     = true
}

variable "chart_version" {
  type        = string
  description = "Tempo chart version"
  default     = "1.23.3"
}

variable "release_name" {
  type        = string
  description = "tempo release name"
  default     = "tempo"
}

variable "configs" {
  type = object({
    storage = optional(object({
      backend = optional(string, "local")
      backend_configuration = optional(map(any), {
        local = { path = "/var/tempo/traces" },
        wal   = { path = "/var/tempo/wal" }
      })
    }), {})
    enable_metrics_generator = optional(bool, true)
    enable_service_monitor   = optional(bool, false)
    tempo_role_name          = optional(string, "tempo-role")

    persistence = optional(object({
      enabled       = optional(bool, true)
      size          = optional(string, "20Gi")
      storage_class = optional(string, "")
    }), {})

    metrics_generator = optional(object({
      enabled    = optional(bool, true)
      remote_url = optional(string, null)
    }), {})

    service_account = optional(object({
      name        = optional(string, "tempo")
      annotations = optional(map(string), {})
    }), {})
  })
}

variable "metrics_generator_remote_url" {
  type        = string
  default     = null
  nullable    = true
  description = "Selector-resolved metrics-generator remote-write URL. A non-null value takes precedence over chart values."
}

variable "service_monitor_enabled" {
  type        = bool
  default     = null
  nullable    = true
  description = "Selector-resolved Prometheus ServiceMonitor state; null preserves the configs request for direct child use."
}

variable "extra_configs" {
  type        = any
  default     = {}
  description = "Allows to pass extra/custom configs to tempo helm chart, this configs will deep-merged with all generated internal configs and can override the default set ones. All available options can be found in for the specified chart version here: https://artifacthub.io/packages/helm/grafana/tempo?modal=values"
}
