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

variable "sending_quota_standard_options" {
  type = object({
    min = optional(number)
    max = optional(number)
  })
  default     = { max = 100000 }
  description = "Standard options (min/max) for Sending Quota gauge"
}
