variable "namespace" {
  type        = string
  description = "namespace to use for deployment"
  default     = "monitoring"
}

variable "create_namespace" {
  type        = bool
  description = "Whether create namespace if not exist"
  default     = true
}

variable "chart_version" {
  type        = string
  description = "victoria metrics cluster chart version"
  default     = "0.31.0"
}

variable "release_name" {
  type        = string
  description = "victoria metrics release name"
  default     = "victoria-metrics"
}

variable "agent_enabled" {
  type        = bool
  description = "Whether to render the VMAgent custom resource as the active Kubernetes scraper."
  default     = false
}

variable "agent_standalone" {
  type        = bool
  description = "Whether VMAgent runs without kube-prometheus-stack and must own native Kubernetes component discovery."
  default     = false
}

variable "operator_enabled" {
  type        = bool
  description = "Whether to install the VictoriaMetrics Operator, its CRDs/RBAC, and the dependent custom-resource release."
  default     = false
}

variable "operator_chart_version" {
  type        = string
  description = "Pinned VictoriaMetrics Operator Helm chart version."
  default     = "0.67.2"
}

variable "operator_release_name" {
  type        = string
  description = "VictoriaMetrics Operator Helm release name."
  default     = "victoria-metrics-operator"
}

variable "operator_extra_configs" {
  type        = any
  description = "Non-protected VictoriaMetrics Operator chart overrides."
  default     = {}
}

variable "prometheus_converter_enabled" {
  type        = bool
  description = "Whether the Operator converts Prometheus monitor resources during a dual-backend migration."
  default     = true
}

variable "agent_name" {
  type        = string
  description = "Name of the selector-managed VMAgent custom resource."
  default     = "victoria-metrics-agent"

  validation {
    condition = (
      length(var.agent_name) <= 253 &&
      alltrue([
        for label in split(".", var.agent_name) :
        length(label) >= 1 &&
        length(label) <= 63 &&
        can(regex("^[a-z0-9]([-a-z0-9]*[a-z0-9])?$", label))
      ])
    )
    error_message = "agent_name must be a valid Kubernetes DNS subdomain name."
  }

}

variable "agent_replica_count" {
  type        = number
  description = "Replica count for the selector-managed VMAgent custom resource."
  default     = 1

  validation {
    condition = (
      var.agent_replica_count >= 1 &&
      floor(var.agent_replica_count) == var.agent_replica_count
    )
    error_message = "agent_replica_count must be a positive integer."
  }
}

variable "agent_extra_scrape_configs" {
  type        = any
  description = "Non-secret inlineScrapeConfig entries for the VMAgent custom resource; direct child callers replacing a module integration must disable its matching agent_*_enabled input."
  default     = []
}

variable "agent_extra_configs" {
  type        = any
  description = "Non-protected VMAgent spec overrides."
  default     = {}
}

variable "agent_kubelet_scrape_enabled" {
  type        = bool
  description = "Whether the active VMAgent renders a native VMNodeScrape for the kubelet /metrics endpoint."
  default     = true
}

variable "agent_cadvisor_scrape_enabled" {
  type        = bool
  description = "Whether the active VMAgent renders a native VMNodeScrape for the kubelet /metrics/cadvisor endpoint."
  default     = true
}

variable "agent_resource_scrape_enabled" {
  type        = bool
  description = "Whether the active VMAgent renders the optional kubelet /metrics/resource VMNodeScrape."
  default     = false
}

variable "agent_kubelet_metrics" {
  type        = list(string)
  description = "Union of metric-name patterns retained from native node scrapes; known patterns are routed to matching kubelet, cAdvisor, or resource endpoints, while unknown patterns apply to all enabled endpoints."
  default = [
    "container_cpu_.*",
    "container_memory_.*",
    "container_network_.*",
    "pod_cpu_usage_seconds_total",
    "pod_memory_working_set_bytes",
    "kubelet_volume_stats.*",
    "volume_operation_total_seconds.*",
    "container_fs_.*",
  ]
}

variable "agent_kubernetes_component_scrapes" {
  type = object({
    namespace            = optional(string, "kube-system")
    api_server_namespace = optional(string, "default")
    api_server           = optional(bool, false)
    core_dns             = optional(bool, true)
    kube_proxy           = optional(bool, true)
    controller_manager   = optional(bool, false)
    scheduler            = optional(bool, false)
    etcd                 = optional(bool, true)
    controller_manager_tls = optional(object({
      ca_file              = optional(string, null)
      server_name          = optional(string, null)
      insecure_skip_verify = optional(bool, false)
    }), null)
    scheduler_tls = optional(object({
      ca_file              = optional(string, null)
      server_name          = optional(string, null)
      insecure_skip_verify = optional(bool, false)
    }), null)
  })
  description = "Native Kubernetes component discovery rendered only for a standalone VictoriaMetrics collector."
  default     = {}

  validation {
    condition = alltrue([
      !var.agent_kubernetes_component_scrapes.controller_manager ||
      try(var.agent_kubernetes_component_scrapes.controller_manager_tls.insecure_skip_verify, false) ||
      try(length(trimspace(var.agent_kubernetes_component_scrapes.controller_manager_tls.ca_file)) > 0, false),
      !var.agent_kubernetes_component_scrapes.scheduler ||
      try(var.agent_kubernetes_component_scrapes.scheduler_tls.insecure_skip_verify, false) ||
      try(length(trimspace(var.agent_kubernetes_component_scrapes.scheduler_tls.ca_file)) > 0, false),
    ])
    error_message = "Enabled controller-manager and scheduler scrapes require explicit TLS settings with either a non-empty CA file path or insecure_skip_verify=true."
  }
}

variable "agent_kube_state_metrics_enabled" {
  type        = bool
  description = "Whether to render the native KSM VMServiceScrape when the remaining collector and exporter gates also pass."
  default     = true
}

variable "agent_kube_state_metrics_namespace" {
  type        = string
  description = "Namespace containing the independent kube-state-metrics Service."
  default     = "monitoring"
}

variable "agent_kube_state_metrics_release_name" {
  type        = string
  description = "Helm instance label of the independent kube-state-metrics Service."
  default     = "kube-state-metrics"
}

variable "agent_kube_state_metrics_fullname" {
  type        = string
  description = "Resolved name of the independent kube-state-metrics Service; the native VMServiceScrape adds a victoria-metrics suffix to avoid converter ownership collisions."
  default     = "prometheus-kube-state-metrics"
}

variable "agent_node_exporter_enabled" {
  type        = bool
  description = "Whether to render the native node-exporter VMServiceScrape when VMAgent is active."
  default     = false
}

variable "agent_node_exporter_namespace" {
  type        = string
  description = "Namespace containing the independent node-exporter Service."
  default     = "monitoring"
}

variable "agent_node_exporter_release_name" {
  type        = string
  description = "Helm instance label of the independent node-exporter Service."
  default     = "node-exporter"
}

variable "agent_node_exporter_fullname" {
  type        = string
  description = "Resolved name of the independent node-exporter Service."
  default     = "prometheus-node-exporter"
}

variable "agent_tempo_enabled" {
  type        = bool
  default     = false
  description = "Whether to render a native Tempo VMServiceScrape."
}

variable "agent_tempo_namespace" {
  type        = string
  default     = "monitoring"
  description = "Namespace containing Tempo."
}

variable "agent_tempo_release_name" {
  type        = string
  default     = "tempo"
  description = "Tempo Helm release name used by native discovery."
}

variable "agent_tempo_query_enabled" {
  type        = bool
  default     = false
  description = "Whether Tempo Query exposes the optional jaeger-metrics port."
}

variable "agent_loki_enabled" {
  type        = bool
  default     = false
  description = "Whether to render a native Loki VMServiceScrape."
}

variable "agent_loki_namespace" {
  type        = string
  default     = "monitoring"
  description = "Namespace containing Loki."
}

variable "agent_loki_release_name" {
  type        = string
  default     = "loki"
  description = "Loki Helm release name used by native discovery."
}

variable "configs" {
  type = object({
    retention_period = optional(string, "30d")
    vmstorage = optional(object({
      replica_count = optional(number, 3)
      storage_class = optional(string, "")
      storage_size  = optional(string, "100Gi")
      access_modes  = optional(list(string), ["ReadWriteOnce"])
    }), {})
    vminsert = optional(object({
      replica_count = optional(number, 2)
    }), {})
    vmselect = optional(object({
      replica_count = optional(number, 2)
    }), {})
  })
  description = "Values to send to VictoriaMetrics helm chart"
  default     = {}
}

variable "extra_configs" {
  type        = any
  default     = {}
  description = "Additional VictoriaMetrics cluster values. The derived vminsert/vmselect service identity and port contract takes precedence."
}
