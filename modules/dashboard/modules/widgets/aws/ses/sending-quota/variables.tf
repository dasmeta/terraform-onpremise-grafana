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
  default = ""
}

variable "coordinates" {
  type = object({
    x      = number
    y      = number
    width  = number
    height = number
  })
}

variable "min" {
  type        = number
  default     = null
  nullable    = true
  description = "Standard options: min (null = auto in Grafana)"
}

variable "max" {
  type        = number
  default     = null
  nullable    = true
  description = "Standard options: max (null = auto in Grafana)"
}
