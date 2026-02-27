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

variable "standard_options" {
  type = object({
    min = optional(number)
    max = optional(number)
  })
  default     = { max = 100000 }
  description = "Standard options: min/max for the gauge (sending quota scale)"
}
