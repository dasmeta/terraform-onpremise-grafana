variable "alert_interval_seconds" {
  type        = number
  default     = 10
  description = "The interval, in seconds, at which all rules in the group are evaluated. If a group contains many rules, the rules are evaluated sequentially."
}

variable "alert_rules" {
  type = list(object({
    name                 = string                          # The name of the alert rule
    no_data_state        = optional(string, "NoData")      # Describes what state to enter when the rule's query returns No Data
    exec_err_state       = optional(string, "Error")       # Describes what state to enter when the rule's query is invalid and the rule cannot be executed
    summary              = optional(string, "")            # Rule annotation as a summary
    priority             = optional(string, "P2")          # Rule priority level: P2 is for non-critical alerts, P1 will be set for critical alerts
    folder_name          = optional(string, "Main Alerts") # Grafana folder name in which the rule will be created
    datasource           = string                          # Name of the datasource used for the alert
    expr                 = optional(string, null)          # Full expression for the alert
    metric_name          = optional(string, "")            # Prometheus metric name which queries the data for the alert
    metric_function      = optional(string, "")            # Prometheus function used with metric for queries, like rate, sum etc.
    metric_interval      = optional(string, "")            # The time interval with using functions like rate
    settings_mode        = optional(string, "replaceNN")   # The mode used in B block, possible values are Strict, replaceNN, dropNN
    settings_replaceWith = optional(number, 0)             # The value by which NaN results of the query will be replaced
    filters              = optional(any, {})               # Filters object to identify each service for alerting
    function             = optional(string, "mean")        # One of Reduce functions which will be used in B block for alerting
    equation             = string                          # The equation in the math expression which compares B blocks value with a number and generates an alert if needed. Possible values: gt, lt, gte, lte, e
    threshold            = number                          # The value against which B blocks are compared in the math expression
  }))
  default     = []
  description = "This varibale describes alert folders, groups and rules."
}
