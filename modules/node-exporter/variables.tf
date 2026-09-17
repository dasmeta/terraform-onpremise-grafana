variable "namespace" {
  type        = string
  default     = "monitoring"
  description = "Namespace where node-exporter is deployed."
}

variable "create_namespace" {
  type        = bool
  default     = true
  description = "Whether Helm may create the target namespace."
}

variable "chart_version" {
  type        = string
  default     = "4.47.1"
  description = "Pinned Prometheus Community prometheus-node-exporter chart version."
}

variable "release_name" {
  type        = string
  default     = "node-exporter"
  description = "Independent node-exporter Helm release name."
}

variable "fullname_override" {
  type        = string
  default     = "prometheus-node-exporter"
  description = "Stable full name used for node-exporter resources and Service discovery."
}

variable "resources" {
  type = object({
    requests = optional(object({
      cpu    = optional(string, "100m")
      memory = optional(string, "200Mi")
    }), {})
    limits = optional(object({
      cpu    = optional(string, "200m")
      memory = optional(string, "500Mi")
    }), {})
  })
  default     = {}
  description = "Node-exporter container requests and limits."
}

variable "prometheus_monitor_enabled" {
  type        = bool
  default     = true
  description = "Whether the independent chart creates the active Prometheus ServiceMonitor."
}

variable "prometheus_release_name" {
  type        = string
  default     = "prometheus"
  description = "Prometheus Helm release label selected by the Prometheus custom resource."
}

variable "extra_configs" {
  type        = any
  default     = {}
  description = "Additional chart values applied before selector-owned identity, resources, and scrape settings."
}
