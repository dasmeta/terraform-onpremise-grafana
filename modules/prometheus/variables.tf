variable "namespace" {
  type        = string
  description = "namespace to use for deployment"
  default     = "monitoring"
}

variable "chart_version" {
  type        = string
  description = "prometheus chart version"
  default     = "75.8.0"
}

variable "configs" {
  type = object({
    retention_days = optional(string, "15d")
    storage_class  = optional(string, "")
    storage_size   = optional(string, "100Gi")
    access_modes   = optional(list(string), ["ReadWriteOnce"])
    resources = optional(object({
      request = optional(object({
        cpu = optional(string, "500m")
        mem = optional(string, "500Mi")
      }), {})
      limit = optional(object({
        cpu = optional(string, "1")
        mem = optional(string, "1Gi")
      }), {})
    }), {})
    replicas                     = optional(number, 2)
    enable_alertmanager          = optional(bool, true)
    scrape_helm_chart_components = optional(bool, true)
    additional_scrape_configs    = optional(any, [])
    ingress = optional(object({
      enabled     = optional(bool, false)
      type        = optional(string, "nginx")
      public      = optional(bool, true)
      tls_enabled = optional(bool, true)

      annotations = optional(map(string), {})
      hosts       = optional(list(string), ["prometheus.example.com"])
      path        = optional(list(string), ["/"])
      path_type   = optional(string, "Prefix")
    }), {})
    kubelet_metrics = optional(list(string), ["container_cpu_.*", "container_memory_.*", "kube_pod_container_status_.*",
      "kube_pod_container_resource_*", "container_network_.*", "kube_pod_resource_limit",
      "kube_pod_resource_request", "pod_cpu_usage_seconds_total", "pod_memory_usage_bytes",
      "kubelet_volume_stats", "volume_operation_total_seconds"]
    )
  })

  description = "Values to send to Prometheus template values file"

  default = {}
}
