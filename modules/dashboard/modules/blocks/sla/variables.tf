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

variable "sla_ingress_type" {
  nullable    = false
  type        = string
  default     = "alb"
  description = "Type of the ingress resource "
}

variable "load_balancer_arn" {
  type        = string
  description = "AWS Application LB arn"
  default     = ""
}
