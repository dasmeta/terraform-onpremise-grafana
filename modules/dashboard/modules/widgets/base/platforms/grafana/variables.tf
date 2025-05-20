variable "name" {
  type = string
}

variable "data_source" {
  type = object({
    uid  = optional(string, null)
    type = optional(string, "prometheus")
  })
  description = "The custom datasource for widget item"
}

variable "coordinates" {
  type = object({
    x : number
    y : number
    width : number
    height : number
  })
}

variable "metrics" {
  type        = any
  default     = []
  description = "Metrics to be displayed on the widget."
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
  type    = number
  default = 3
}

variable "region" {
  type    = string
  default = ""
}

variable "type" {
  type        = string
  default     = "metric"
  description = "The type of widget to be prepared"
}

variable "query" {
  type        = string
  default     = null
  description = "The PromQL query to use for the chart"
}

variable "sources" {
  type        = list(string)
  default     = []
  description = "Log groups list for Logs Insights query"
}

variable "view" {
  type        = string
  default     = null
  description = "The view for log insights and alarm widgets"
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

variable "decimals" {
  type        = number
  default     = 0
  description = "The decimals to enable on numbers"
}

variable "unit" {
  type        = string
  default     = ""
  description = "Unit used for widget metric"
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

variable "description" {
  type        = string
  description = "Description for the widget"
  default     = ""
}

variable "thresholds" {
  type = object({
    mode = string
    steps = list(object({
      color = string
      value = number
    }))
  })
  description = "Thresholds defined for a widget"
  default = {
    mode = "absolute"
    steps = [
      {
        color = "green"
        value = null
      },
      {
        color = "red"
        value = 80
      },
    ]
  }
}

variable "cloudwatch_targets" {
  type = list(object({
    query_mode  = optional(string, "Metrics") # Logs or Metrics
    region      = optional(string, "eu-central-1")
    namespace   = optional(string, "AWS/EC2")
    metric_name = optional(string, "CPUUtilization")
    dimensions  = optional(map(string), {})
    statistic   = optional(string, "Average")
    period      = optional(string, "300")
    refId       = optional(string, "A")
  }))
  description = "Target section of the cloudwatch based widget"
  default     = []
}

variable "loki_targets" {
  type = list(object({
    expr          = string
    format        = optional(string, "time_series")
    refId         = optional(string, "A")
    legend_format = optional(string, "Errors ({{instance}})")
    queryType     = optional(string, "range")
    hide          = optional(bool, false)
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

variable "color_mode" {
  type        = string
  description = "Color mode used for a widget"
  default     = "palette-classic"
}

variable "targets" {
  type        = any
  description = "Custom targets to use"
  default     = null
}
