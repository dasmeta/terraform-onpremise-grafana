variable "datasource_uid" {
  type        = string
  default     = "loki"
  description = "The custom datasource for widget item"
}

variable "deployment" {
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
  default = "3"
}
