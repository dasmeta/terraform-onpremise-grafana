# variable "data_source" {
#   type = object({
#     uid  = optional(string, null)
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
  default = "3"
}

variable "only_5xx" {
  type    = bool
  default = false
}

variable "by_host" {
  type    = bool
  default = false
}

variable "by_path" {
  type    = bool
  default = false
}

variable "by_status_path" {
  type    = bool
  default = false
}
