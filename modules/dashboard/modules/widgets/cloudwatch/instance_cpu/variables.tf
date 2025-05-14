variable "data_source" {
  type = object({
    uid  = optional(string, "cloudwatch")
    type = optional(string, "Cloudwatch")
  })
  description = "The custom datasource for widget item"
}

variable "namespace" {
  type    = string
  default = "default"
}

variable "account_id" {
  type    = string
  default = null
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
  type    = number
  default = 60
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
