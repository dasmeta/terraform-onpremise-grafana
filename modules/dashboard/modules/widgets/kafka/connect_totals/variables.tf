variable "datasource_uid" {
  type        = string
  default     = "prometheus"
  description = "Prometheus datasource UID"
}

variable "namespace" {
  type        = string
  description = "Kubernetes namespace used to select Kafka exporter metrics"
}

variable "extra_filters" {
  type        = string
  default     = ""
  description = "Additional PromQL label matchers, for example job=~\"kafka-exporter\""
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

variable "coordinates" {
  type = object({
    x : number
    y : number
    width : number
    height : number
  })
  description = "Panel coordinates"
}

variable "period" {
  type        = string
  default     = "$__rate_interval"
  description = "Prometheus range interval"
}
