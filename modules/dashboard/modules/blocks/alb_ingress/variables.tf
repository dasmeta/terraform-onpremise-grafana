
variable "load_balancer_arn" {
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
