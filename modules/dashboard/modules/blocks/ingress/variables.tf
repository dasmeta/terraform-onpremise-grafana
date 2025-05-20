
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
  default     = "cloudwatch"
  description = "datasource uid for the metrics"
}
