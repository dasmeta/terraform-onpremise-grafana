variable "namespace" {
  type        = string
  description = "namespace for tempo deployment"
  default     = "monitoring"
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
      remote_url = optional(string, "http://prometheus-kube-prometheus-prometheus.monitoring.svc.cluster.local:9090/api/v1/write")
    }), {})

    service_account = optional(object({
      name        = optional(string, "tempo")
      annotations = optional(map(string), {})
    }), {})
  })
}
