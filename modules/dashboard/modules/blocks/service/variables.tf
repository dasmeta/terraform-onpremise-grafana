variable "name" {
  type        = string
  description = "Service nameD"
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
  type        = string
  default     = "prometheus"
  description = "datasource uid for the metrics"
}

variable "datasource_type" {
  type        = string
  default     = "prometheus"
  description = "datasource type"
}
