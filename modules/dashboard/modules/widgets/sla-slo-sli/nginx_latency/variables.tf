variable "datasource_uid" {
  type        = string
  default     = "prometheus"
  description = "prometheus datasource type uid to use for widget"
}

variable "balancer_name" {
  type    = string
  default = null
}

variable "histogram" {
  type    = bool
  default = false
}

variable "account_id" {
  type    = string
  default = null
}

variable "region" {
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
  default = "3"
}
