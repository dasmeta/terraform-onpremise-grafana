# variable "data_source" {
#   type = object({
#     uid  = optional(string, "prometheus")
#     type = optional(string, "prometheus")
#   })
#   description = "The custom datasource for widget item"
# }

variable "datasource_uid" {
  type    = string
  default = "prometheus"
}

variable "datasource_type" {
  type    = string
  default = "prometheus"
}
variable "ingress_type" {
  type    = string
  default = "nginx"
}

variable "problem" {
  type        = number
  default     = 2
  description = "The number which indicates the max timeout above which we have problem"
}

variable "acceptable" {
  type        = number
  default     = 1
  description = "The number which indicates the acceptable timeout"
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
  default = "$__rate_interval"
}

variable "by_host" {
  type    = bool
  default = false
}

variable "filter" {
  type        = string
  default     = ""
  description = "Allows to define additional filter on metric"
}
