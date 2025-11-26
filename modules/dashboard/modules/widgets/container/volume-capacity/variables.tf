
variable "datasource_uid" {
  type    = string
  default = "prometheus"
}

variable "datasource_type" {
  type    = string
  default = "prometheus"
}

variable "container" {
  type = string
}

variable "namespace" {
  type    = string
  default = "default"
}

variable "pvc_name" {
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
