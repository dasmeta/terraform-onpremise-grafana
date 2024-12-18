variable "data_source" {
  type = object({
    uid  = optional(string, null)
    type = optional(string, "prometheus")
  })
  description = "The custom datasource for widget item"
}

variable "ingress_type" {
  type    = string
  default = "nginx"
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
  type    = number
  default = 3
}

variable "only_5xx" {
  type    = bool
  default = false
}

variable "by_host" {
  type    = bool
  default = false
}

variable "by_path" {
  type    = bool
  default = false
}

variable "by_status_path" {
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
