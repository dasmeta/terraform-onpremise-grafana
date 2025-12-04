variable "data_source" {
  type = object({
    uid  = string
    type = string
  })
  description = "The custom datasource for widget item"
}

variable "name" {
  type = string
}

variable "coordinates" {
  type = object({
    x : number
    y : number
    width : number
    height : number
  })
}

variable "legend_format" {
  type        = string
  default     = ""
  description = "Legend format"
}

variable "metrics" {
  type        = any
  default     = []
  description = "Metrics to be displayed on the widget."
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
    id         = optional(string, null)
  }))
  default     = []
  description = "Custom metric expressions over metrics, note that metrics have auto generated m1,m2,..., m{n} ids"
}

variable "defaults" {
  type        = any
  default     = {}
  description = "Default values that will be passed to all metrics."
}

variable "stat" {
  type    = string
  default = "Average"
}

variable "period" {
  type    = string
  default = "3"
}

variable "region" {
  type    = string
  default = ""
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

variable "type" {
  type        = string
  default     = "metric"
  description = "The type of widget to be prepared"
}

variable "query" {
  type = list(object({
    datasource = object({
      uid  = optional(string, "__expr__")
      type = optional(string, "__expr__")
      name = optional(string, "Expression")
    })
    expression = optional(string, "")
    refId      = optional(string, "")
    querymode  = optional(string, "")
    type       = optional(string, "math")
    hide       = optional(bool, false)
  }))
  default     = []
  description = "The PromQL query to use for the chart"
}

variable "sources" {
  type        = list(string)
  default     = []
  description = "Log groups list for Logs Insights query"
}

variable "annotations" {
  type        = any
  default     = null
  description = "The annotations option for alarm widgets"
}

variable "alarms" {
  type        = list(string)
  default     = null
  description = "The list of alarm_arns used for properties->alarms option in alarm widgets"
}

variable "properties_type" {
  type        = string
  default     = null
  description = "The properties->type option for alarm widgets"
}

variable "yAxis" {
  type        = any
  default     = { left = {} }
  description = "Widget Item common yAxis option (applied only metric type widgets)."
}

variable "setPeriodToTimeRange" {
  type        = bool
  default     = null
  description = "setPeriodToTimeRange of widget"
}

variable "singleValueFullPrecision" {
  type        = bool
  default     = null
  description = "singleValueFullPrecision of widget"
}

variable "sparkline" {
  type        = bool
  default     = null
  description = "sparkline of widget"
}

variable "trend" {
  type        = bool
  default     = null
  description = "trend of widget"
}

variable "start" {
  type        = string
  default     = null
  description = "start of widget"
}

variable "end" {
  type        = string
  default     = null
  description = "end of widget"
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

variable "options" {
  type = object({
    legend = object({
      calcs       = optional(list(string), [])
      displayMode = optional(string, "list")
      placement   = optional(string, "bottom")
      show_legend = optional(bool, true)
    })
    tooltip = optional(object({
      mode = optional(string, "single")
      sort = optional(string, "none")
    }), {})
  })
  default = {
    legend = {
      calcs       = []
      displayMode = "list"
      placement   = "bottom"
      show_legend = true
    }
    tooltip = {
      mode = "single"
      sort = "none"
    }
  }
  description = "Configuration options for widget legend and tooltip."
}

variable "unit" {
  type        = string
  default     = ""
  description = "Unit used for widget metric"
}

variable "description" {
  type        = string
  description = "Description for the widget"
  default     = ""
}

variable "thresholds" {
  type = object({
    mode = optional(string, "absolute")
    steps = optional(list(object({
      color = string
      value = number
      })), [
      {
        color = "green"
        value = null
      },
      {
        color = "red"
        value = 80
      },
    ])
  })
  description = "Thresholds defined for a widget"
  default     = {}
}

variable "color_mode" {
  type        = string
  description = "Color mode used for a widget"
  default     = "palette-classic"
}

variable "cloudwatch_targets" {
  type = list(object({
    datasource_uid = optional(string, "cloudwatch")
    query_mode     = optional(string, "Metrics") # Logs or Metrics
    region         = optional(string, "eu-central-1")
    namespace      = optional(string, "AWS/EC2")
    metric_name    = optional(string, "CPUUtilization")
    dimensions     = optional(map(string), {})
    statistic      = optional(string, "Average")
    period         = optional(string, "300")
    refId          = optional(string, "A")
    id             = optional(string, "")
    hide           = optional(bool, false)
    label          = optional(string, "")
    widget_name    = optional(string, "widget_cloudwatch")
  }))
  description = "Target section of the cloudwatch based widget"
  default     = []
}

variable "loki_targets" {
  type = list(object({
    expr      = string
    refId     = optional(string, "")
    direction = optional(string, "backward")
    queryType = optional(string, "range")
    hide      = optional(bool, false)
    label     = optional(string, "Logs")
    limit     = optional(number, 10)
  }))
  description = "Target section of Loki based widget"
  default     = []
}

variable "tempo_targets" {
  type = list(object({
    filters = optional(list(any), [])
    limit   = optional(number, 20)
    query   = string
  }))
  description = "Target section of tempo based widget"
  default     = []
}

variable "transformations" {
  type        = any
  description = "Custom transformations to use"
  default     = null
}
