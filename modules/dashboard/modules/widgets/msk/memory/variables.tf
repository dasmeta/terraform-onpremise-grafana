variable "datasource_uid" {
  type    = string
  default = "cloudwatch"
}

variable "region" {
  type    = string
  default = ""
}

variable "period" {
  type    = string
  default = ""
}

variable "cluster_names" {
  type        = list(string)
  description = "List of MSK cluster names (CloudWatch Cluster Name dimension)"
}

variable "broker_ids" {
  type        = list(string)
  description = "Broker IDs to include in broker-level MSK metrics"
  default     = ["1", "2", "3"]
}

variable "coordinates" {
  description = "Grid position for the panel"
  type = object({
    x      = number
    y      = number
    width  = number
    height = number
  })
}
