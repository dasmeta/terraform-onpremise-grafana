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
  default = "$__interval"
}

variable "parser" {
  type        = string
  default     = ""
  description = "The logs parser to use before filtration"
}

variable "error_filter" {
  type        = string
  default     = "detected_level=\"error\""
  description = "The error logs filter expression"
}

variable "warn_filter" {
  type        = string
  default     = "detected_level=\"warn\""
  description = "The warn logs filter expression"
}
