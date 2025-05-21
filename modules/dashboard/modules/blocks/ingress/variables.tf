
variable "balancer_name" {
  type        = string
  description = "ALB name"
}

variable "region" {
  type    = string
  default = ""
}

variable "datasource_uid" {
  nullable    = false
  type        = string
  default     = "prometheus"
  description = "datasource uid for the metrics"
}
