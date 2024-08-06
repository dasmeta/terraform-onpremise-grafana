variable "data_source" {
  type = object({
    uid  = optional(string, null)
    type = optional(string, "prometheus")
  })
  description = "The custom datasource for widget item"
}

variable "title" {
  type = string
}

variable "metrics" {
  type = any
  ## sample form
  # [
  #   { MetricName = "errors1", "ClusterName" = "my-cluster-name" },
  #   { MetricName = "errors2", "color" = "#d62728" }
  #   { MetricName = "errors3", accountId : "123234365765", "color" = "#d62728" }
  # ]
}

variable "expressions" {
  type = list(object({
    expression = string
    label      = optional(string, null)
    accountId  = optional(string, null)
    visible    = optional(bool, null)
    color      = optional(string, null)
    yAxis      = optional(string, null)
    region     = optional(string, null)
  }))
  default     = []
  description = "Custom metric expressions over metrics, note that metrics have auto generated m1,m2,..., m{n} ids"
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

variable "account_id" {
  type    = string
  default = null
}

variable "region" {
  type    = string
  default = ""
}

variable "period" {
  type    = number
  default = 3
}

variable "stat" {
  type    = string
  default = "Average"
}

variable "anomaly_detection" {
  type        = bool
  default     = false
  description = "Enables anomaly detection on widget metrics"
}

variable "anomaly_deviation" {
  type        = number
  default     = 6
  description = "Deviation of the anomaly band"
}

variable "yAxis" {
  type        = any
  default     = { left = { min = 0 } }
  description = "Widget Item common yAxis option (applied only metric type widgets)."
}

variable "view" {
  type        = string
  default     = null
  description = "The view for log insights and alarm widgets"
}

variable "decimals" {
  type        = number
  default     = 0
  description = "The decimals to enable on numbers"
}

variable "fillOpacity" {
  type        = number
  default     = 0
  description = "The fillOpacity value"
}
