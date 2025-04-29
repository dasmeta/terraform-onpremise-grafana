variable "cluster_name" {
  type        = string
  description = "name of the eks cluster"
}

variable "namespace" {
  type        = string
  description = "namespace for tempo deployment"
  default     = "monitoring"
}

variable "chart_version" {
  type        = string
  description = "grafana chart version"
  default     = "1.20.0"
}

variable "configs" {
  type = object({
    tempo_role_arn           = optional(string, "")
    storage_backend          = optional(string, "s3") # "local" or "s3"
    bucket_name              = optional(string, "")
    enable_metrics_generator = optional(bool, true)
    enable_service_monitor   = optional(bool, true)
    tempo_role_name          = optional(string, "tempo-s3-role")

    persistence = optional(object({
      enabled       = optional(bool, true)
      size          = optional(string, "20Gi")
      storage_class = optional(string, "gp2")
    }), {})

    metrics_generator = optional(object({
      enabled    = optional(bool, true)
      remote_url = optional(string, "http://prometheus-kube-prometheus-prometheus.monitoring.svc.cluster.local:9090/api/v1/write")
    }), {})

    service_account = optional(object({
      name        = optional(string, "tempo-serviceaccount")
      annotations = optional(map(string), {})
    }), {})
  })
}
