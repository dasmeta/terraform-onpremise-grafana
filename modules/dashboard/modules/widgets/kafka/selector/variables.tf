variable "namespace" {
  type        = string
  default     = ""
  description = "Optional PromQL namespace matcher"
}

variable "extra_filters" {
  type        = string
  default     = ""
  description = "Optional extra PromQL matchers, for example job=~\"example-connect-status-exporter\""
}

variable "cluster_label" {
  type        = string
  default     = ""
  description = "Optional cluster label name"
}

variable "cluster" {
  type        = string
  default     = ""
  description = "Optional cluster label value"
}
