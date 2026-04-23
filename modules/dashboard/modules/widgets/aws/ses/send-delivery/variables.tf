variable "datasource_uid" {
  type    = string
  default = "cloudwatch"
}

variable "region" {
  type    = string
  default = ""
}

variable "period" {
  type    = string
  default = "3600"
}

variable "coordinates" {
  type = object({
    x      = number
    y      = number
    width  = number
    height = number
  })
}
