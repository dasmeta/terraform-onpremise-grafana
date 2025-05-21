
variable "load_balancer_arn" {
  type        = string
  description = "ALB AWS arn"
  default     = ""
}

variable "region" {
  type    = string
  default = "eu-central-1"
}

variable "datasource_uid" {
  nullable    = false
  type        = string
  default     = "cloudwatch"
  description = "datasource uid for the metrics"
}
