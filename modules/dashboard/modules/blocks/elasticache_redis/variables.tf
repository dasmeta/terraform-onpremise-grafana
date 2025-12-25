variable "cache_cluster_ids" {
  type        = list(string)
  description = "List of CacheClusterId for ElastiCache Redis"
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
  default     = "Redis (Queue)"
  description = "Widget block name"
}
