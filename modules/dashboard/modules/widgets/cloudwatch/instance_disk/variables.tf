variable "datasource_uid" {
  type    = string
  default = "cloudwatch"
}

variable "namespace" {
  type    = string
  default = "default"
}

variable "region" {
  type    = string
  default = ""
}

# position
variable "coordinates" {
  type = object({
    x : number
    y : number
    width : number
    height : number
  })
}

# stats
variable "period" {
  type    = string
  default = ""
}

variable "dimensions" {
  type        = map(string)
  description = "List of instance attributes for filtering instances"
  default     = {}
}

variable "search" {
  type        = map(any)
  description = "The Cloudwatch search expression to use for filtering metrics"
  default     = {}
}
