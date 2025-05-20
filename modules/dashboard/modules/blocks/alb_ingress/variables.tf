
variable "load_balancer_arn" {
  type        = string
  description = "ALB AWS arn"
  default     = "eu-central-1"
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
