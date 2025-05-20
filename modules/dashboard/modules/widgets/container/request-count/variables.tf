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

variable "only_5xx" {
  type    = bool
  default = false
}

variable "target_group_name" {
  type    = string
  default = null
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
