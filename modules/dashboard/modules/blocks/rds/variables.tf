variable "db_identifiers" {
  type        = list(string)
  description = "List of DBInstanceIdentifier for RDS instances"
}

variable "region" {
  type    = string
  default = "eu-central-1"
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

variable "block_name" {
  type        = string
  default     = "RDS"
  description = "Widget block name"
}
