variable "data_source" {
  type = object({
    uid  = optional(string, "prometheus")
    type = optional(string, "prometheus")
  })
  description = "The custom datasource for widget item"
}

variable "ingress_type" {
  type    = string
  default = "nginx"
}

variable "pod" {
  type = string
}

variable "namespace" {
  type    = string
  default = "default"
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
  default = 3
}
