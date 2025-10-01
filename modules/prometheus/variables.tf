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

variable "release_name" {
  type        = string
  description = "prometheus release name"
  default     = "prometheus"
}

variable "configs" {
  type = object({
    retention_days = optional(string, "15d")
    storage_class  = optional(string, "")
    storage_size   = optional(string, "100Gi")
    access_modes   = optional(list(string), ["ReadWriteOnce"])
    resources = optional(object({
      request = optional(object({
        cpu = optional(string, "1")
        mem = optional(string, "2500Mi")
      }), {})
      limit = optional(object({
        cpu = optional(string, "2")
        mem = optional(string, "3Gi")
      }), {})
    }), {})
    replicas                     = optional(number, 1)
    enable_alertmanager          = optional(bool, true)
    scrape_helm_chart_components = optional(bool, false) # enable scraping all servicemonitors. The chart by default has disabled scraping all servicemonitors. https://artifacthub.io/packages/helm/prometheus-community/kube-prometheus-stack#prometheus-io-scrape
    additional_scrape_configs    = optional(any, [])     # allows to specify additional scrape configs for prometheus. Example can be found in tests/prometheus-additional-scrape-configs/1-example.tf
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
      "kube_pod_container_resource_.*", "container_network_.*", "kube_pod_resource_limit",
      "kube_pod_resource_request", "pod_cpu_usage_seconds_total", "pod_memory_usage_bytes",
      "kubelet_volume_stats.*", "volume_operation_total_seconds.*", "container_fs_.*"]
    )
    additional_args = optional(list(object({
      name  = string
      value = string
      })), [
      {
        name  = "query.max-concurrency"
        value = "64"
      },
      {
        name  = "query.timeout"
        value = "2m"
      },
      {
        name  = "query.max-samples"
        value = "75000000"
      }
    ])
  })

  description = "Values to send to Prometheus template values file"

  default = {}
}
