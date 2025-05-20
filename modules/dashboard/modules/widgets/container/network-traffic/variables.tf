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
