variable "data_source" {
  type = object({
    uid  = optional(string, "prometheus")
    type = optional(string, "prometheus")
  })
  description = "The custom datasource for widget item"
}

variable "container" {
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
  default = 60
}

variable "by_pod" {
  type    = bool
  default = false
}

variable "anomaly_detection" {
  type        = bool
  default     = false
  description = "Allow to enable anomaly detection on widget metrics"
}

variable "anomaly_deviation" {
  type        = number
  default     = 6
  description = "Deviation of the anomaly band"
}
