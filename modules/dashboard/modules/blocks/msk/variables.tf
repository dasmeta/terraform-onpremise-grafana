variable "cluster_names" {
  type        = list(string)
  description = "List of MSK cluster names (CloudWatch Cluster Name dimension)"
}

variable "broker_ids" {
  type        = list(string)
  description = "Broker IDs to include in broker-level MSK metrics"
  default     = ["1", "2", "3"]
}

variable "consumer_groups" {
  type        = list(string)
  description = "Optional consumer groups for lag panels"
  default     = []
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
  description = "Datasource uid for the metrics"
}

variable "block_name" {
  type        = string
  default     = "MSK"
  description = "Widget block name"
}
