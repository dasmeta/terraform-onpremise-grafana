variable "datasource_uid" {
  type    = string
  default = "prometheus"
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
  type    = string
  default = "$__rate_interval"
}
