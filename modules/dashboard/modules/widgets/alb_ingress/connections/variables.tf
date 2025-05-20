# variable "data_source" {
#   type = object({
#     uid  = optional(string, "prometheus")
#     type = optional(string, "prometheus")
#   })
#   description = "The custom datasource for widget item"
# }

variable "datasource_uid" {
  type    = string
  default = "cloudwatch"
}

variable "datasource_type" {
  type    = string
  default = "Cloudwatch"
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
  type    = string
  default = "60"
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

variable "load_balancer_arn" {
  type        = string
  description = "The aws arn of the alb load balancer"
}
