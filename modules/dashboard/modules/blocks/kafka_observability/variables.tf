variable "namespace" {
  type        = string
  description = "Kubernetes namespace used to select kafka-connect-status-exporter metrics"
}

variable "datasource_uid" {
  type        = string
  default     = "prometheus"
  description = "Prometheus datasource UID"
}

variable "extra_filters" {
  type        = string
  default     = ""
  description = "Additional PromQL label matchers shared by dashboard panels, for example job=~\"example-connect-status-exporter\""
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

variable "period" {
  type        = string
  default     = "$__rate_interval"
  description = "Prometheus range interval used by trend panels"
}

variable "block_name" {
  type        = string
  default     = "Kafka observability"
  description = "Dashboard block title"
}
