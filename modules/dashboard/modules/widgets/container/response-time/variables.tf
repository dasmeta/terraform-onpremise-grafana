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

variable "host" {
  type    = string
  default = null
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
  default = "3"
}
