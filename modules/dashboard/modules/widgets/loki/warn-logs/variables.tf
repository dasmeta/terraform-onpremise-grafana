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

variable "expr" {
  type        = string
  default     = ""
  description = "LogQl expression to get the logs"
}

variable "parser" {
  type        = string
  default     = "logfmt"
  description = "The logs parser to use before filtration"
}

variable "filter" {
  type        = string
  default     = "detected_level=\"warn\""
  description = "The logs filter expression"
}

variable "direction" {
  type        = string
  default     = "backward"
  description = "The direction search of log entries"
}

variable "limit" {
  type        = number
  default     = 10
  description = "The number of log items to fetch"
}
