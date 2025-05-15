variable "data_source" {
  type = object({
    uid  = optional(string, "prometheus")
    type = optional(string, "prometheus")
  })
  description = "The custom datasource for widget item"
}

variable "container" {
  type = string
}

variable "namespace" {
  type    = string
  default = "default"
}

variable "host" {
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
