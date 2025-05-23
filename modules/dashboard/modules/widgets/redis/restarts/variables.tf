variable "data_source" {
  type = object({
    uid  = optional(string, null)
    type = optional(string, "prometheus")
  })
  description = "The custom datasource for widget item"
}

variable "redis_pod" {
  type = string
}

variable "redis_namespace" {
  type        = string
  description = "k8s redis namespace name"
}

variable "cluster" {
  type = string
}

variable "namespace" {
  type    = string
  default = "default"
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
