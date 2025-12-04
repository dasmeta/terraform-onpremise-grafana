variable "data_source" {
  type = object({
    uid  = optional(string, null)
    type = optional(string, "loki")
  })
  description = "The custom datasource for widget item logs"
}

variable "account_id" {
  type    = string
  default = null
}

variable "region" {
  type    = string
  default = ""
}

variable "aggregated_metric" {
  type = string
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
  default = "$__rate_interval"
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
