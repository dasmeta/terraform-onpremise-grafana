variable "datasource_uid" {
  type        = string
  default     = "prometheus"
  description = "prometheus datasource type uid to use for widget"
}

variable "histogram" {
  type    = bool
  default = false
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

variable "filter" {
  type        = string
  default     = ""
  description = "Allows to define additional filter on metrics"
}
