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

variable "host" {
  type        = string
  default     = null
  description = "The service host name"
}

variable "datasource_uid" {
  nullable    = false
  type        = string
  default     = "prometheus"
  description = "datasource uid for the metrics"
}
