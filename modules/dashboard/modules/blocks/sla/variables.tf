variable "balancer_name" {
  type        = string
  description = "ALB name"
}

variable "region" {
  type    = string
  default = ""
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
