variable "name" {
  type        = string
  description = "Dashboard name. Should not contain spaces and special chars."
}

variable "defaults" {
  type = any
  ## valid values
  # object({
  #     period    = number
  #     namespace = string
  #     cluster   = string
  #     width     = number
  #     height    = number
  #   }
  # )
  default     = {}
  description = "Default values to be supplied to all modules."
}

variable "rows" {
  type        = any
  description = "List of widgets to be inserted into the dashboard. See ./modules/widgets folder to see list of available widgets."
}

variable "data_source" {
  type = object({
    uid  = string
    type = optional(string, "prometheus")
  })
  description = "The grafana dashboard global/default datasource, will be used in widget items if they have no their custom ones"
}

variable "variables" {
  type = list(object({
    name        = string
    type        = optional(string, "custom")
    hide        = optional(number, 0)
    includeAll  = optional(bool, false)
    multi       = optional(bool, false)
    query       = optional(string, "")
    queryValue  = optional(string, "")
    skipUrlSync = optional(bool, false)
    options = optional(list(object({
      selected = optional(bool, false)
      value    = string
      text     = optional(string, null)
    })), [])
    }
  ))
  default     = []
  description = "Allows to define variables to be used in dashboard"
}

variable "custom_widgets" {
  type = list(object({
    datasource = optional(object({
      uid  = optional(string, "")
      type = optional(string, "prometheus")
    }), {})
    title              = optional(string, "custom_widget")
    cloudwatch_targets = optional(list(any), [])
    coordinates = optional(object({
      x      = optional(number, 1)
      y      = optional(number, 20)
      width  = optional(number, 6)
      height = optional(number, 1)
    }), {})
  }))
  description = "list of maps to create custom widgets"
  default     = []
}
