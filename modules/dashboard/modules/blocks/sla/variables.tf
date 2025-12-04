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

variable "height" {
  type        = number
  default     = 6
  description = "The height of widgets"
}

variable "filter" {
  type        = string
  default     = ""
  description = "Allows to define additional filter on metrics"
}
