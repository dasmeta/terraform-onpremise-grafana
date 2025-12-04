variable "region" {
  type        = string
  default     = "eu-central-1"
  description = "AWS region"
}

variable "period" {
  type    = string
  default = "auto"
}

variable "datasource_uid" {
  nullable    = false
  type        = string
  default     = "cloudwatch"
  description = "datasource uid for the metrics"
}
