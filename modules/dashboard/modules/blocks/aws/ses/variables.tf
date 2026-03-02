variable "region" {
  type        = string
  default     = "eu-central-1"
  description = "AWS region for SES metrics"
}

variable "period" {
  type    = string
  default = "auto"
}

variable "datasource_uid" {
  nullable    = false
  type        = string
  default     = "cloudwatch"
  description = "Datasource UID for CloudWatch metrics"
}

variable "block_name" {
  type        = string
  default     = "AWS SES"
  description = "Widget block title"
}

variable "min" {
  type        = number
  default     = null
  nullable    = true
  description = "Sending Quota gauge: min (null = auto)"
}

variable "max" {
  type        = number
  default     = null
  nullable    = true
  description = "Sending Quota gauge: max (null = auto)"
}
