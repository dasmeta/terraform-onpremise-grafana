variable "namespace" {
  type        = string
  description = "Kubernetes namespace used to select kafka-connect-status-exporter metrics"
}

variable "datasource" {
  type        = string
  default     = "prometheus"
  description = "Prometheus datasource UID"
}

variable "extra_filters" {
  type        = string
  default     = ""
  description = "Additional PromQL label matchers shared by alert queries"
}

variable "exporter_scrape_filters" {
  type        = string
  default     = ""
  description = "Optional PromQL matchers for the exporter scrape alert; defaults to extra_filters when empty"
}

variable "cluster_label" {
  type        = string
  default     = ""
  description = "Optional cluster label name when exporters expose a cluster identity"
}

variable "cluster" {
  type        = string
  default     = ""
  description = "Optional cluster label value"
}

variable "critical_consumer_groups" {
  type        = list(string)
  default     = []
  description = "Consumer groups that must stay active"
}

variable "idle_consumer_groups" {
  type        = list(string)
  default     = []
  description = "Consumer groups that are intentionally idle and are excluded from empty-member alerts"
}

variable "stopped_connectors" {
  type        = list(string)
  default     = []
  description = "Connectors that are intentionally stopped and are excluded from FAILED alerts"
}

variable "lag_threshold" {
  type        = number
  default     = 0
  description = "Minimum lag growth required to fire the empty-member alert"
}

variable "lag_growth_window" {
  type        = string
  default     = "15m"
  description = "Range window used with increase(kafka_consumergroup_lag[window])"
}

variable "pending_period" {
  type        = string
  default     = "5m"
  description = "Default alert pending duration"
}

variable "failed_state" {
  type        = string
  default     = "failed"
  description = "Connector/task state label value treated as failed. kafka-connect-status-exporter emits lowercase Connect states."
}

variable "dashboard_url" {
  type        = string
  default     = ""
  description = "Optional dashboard URL annotation"
}

variable "runbook_url" {
  type        = string
  default     = ""
  description = "Optional runbook URL annotation"
}

variable "defaults" {
  type        = any
  default     = {}
  description = "Shared alert defaults merged into each rule. Supported keys: enabled, group, pending_period, labels, no_data_state, exec_err_state."
}

variable "alerts" {
  type        = any
  default     = {}
  description = "Per-rule Kafka Connect alert configuration. Supported keys: enabled, pending_period, labels, annotations, connector_failed, task_failed, connect_rest_down, exporter_scrape. All rules stay off unless alerts.enabled is true."
}
