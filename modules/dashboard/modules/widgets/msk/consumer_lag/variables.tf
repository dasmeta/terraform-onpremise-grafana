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

variable "consumer_groups" {
  type        = list(string)
  description = "Consumer groups for DEFAULT MaxOffsetLag and SumOffsetLag series"
  default     = []
}

variable "topics" {
  type        = list(string)
  description = "Optional topics for DEFAULT MaxOffsetLag and SumOffsetLag dimensions. Empty list omits Topic so Grafana can return all topic series."
  default     = []
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
