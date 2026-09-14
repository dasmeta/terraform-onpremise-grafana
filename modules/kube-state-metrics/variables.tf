variable "namespace" {
  type        = string
  default     = "monitoring"
  description = "Namespace where kube-state-metrics is deployed."
}

variable "create_namespace" {
  type        = bool
  default     = true
  description = "Whether Helm may create the target namespace."
}

variable "chart_version" {
  type        = string
  default     = "7.8.1"
  description = "Prometheus Community kube-state-metrics Helm chart version."
}

variable "release_name" {
  type        = string
  default     = "kube-state-metrics"
  description = "Standalone kube-state-metrics Helm release name."
}

variable "fullname_override" {
  type        = string
  default     = "prometheus-kube-state-metrics"
  description = "Full name used for kube-state-metrics Kubernetes resources and Service discovery."
}

variable "prometheus_monitor_enabled" {
  type        = bool
  default     = true
  description = "Whether the standalone chart creates a ServiceMonitor for the active Prometheus collector."
}

variable "prometheus_release_name" {
  type        = string
  default     = "prometheus"
  description = "Prometheus Helm release label selected by the Prometheus custom resource."
}

variable "extra_configs" {
  type        = any
  default     = {}
  description = "Additional kube-state-metrics chart values applied before selector-owned values."
}
