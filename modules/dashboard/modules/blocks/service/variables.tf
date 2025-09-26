variable "name" {
  type        = string
  description = "Service name"
}

variable "namespace" {
  type        = string
  description = "EKS namespace name"
}

variable "region" {
  type    = string
  default = ""
}

variable "pvc_name" {
  type        = string
  description = "PVC name"
  default     = ""
}

variable "host" {
  type        = string
  default     = null
  description = "The service host name"
}

variable "prometheus_datasource_uid" {
  nullable    = false
  type        = string
  default     = "prometheus"
  description = "datasource uid for the metrics widgets"
}

variable "loki_datasource_uid" {
  nullable    = false
  type        = string
  default     = "loki"
  description = "datasource uid for the logs widgets"
}

variable "show_err_logs" {
  type        = bool
  default     = true
  description = "Wether to show the error and warning logs for the deployment"
}

variable "expr" {
  type        = string
  default     = ""
  description = "logql query used to query logs"
}
