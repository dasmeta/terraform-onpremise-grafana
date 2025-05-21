variable "region" {
  type        = string
  default     = "eu-central-1"
  description = "AWS region"
}

variable "datasource_uid" {
  nullable    = false
  type        = string
  default     = "cloudwatch"
  description = "datasource uid for the metrics"
}
