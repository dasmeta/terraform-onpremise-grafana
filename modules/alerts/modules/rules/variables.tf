variable "alert_interval_seconds" {
  type        = number
  default     = 10
  description = "The interval, in seconds, at which all rules in the group are evaluated. If a group contains many rules, the rules are evaluated sequentially."
}

variable "disable_provenance" {
  type        = bool
  default     = true
  description = "Allow modifying the rule groups from other sources than Terraform or the Grafana API."
}

variable "create_folder" {
  type        = bool
  default     = true
  description = "Whether to create one general folder for all alerts"
}

variable "folder_name" {
  type        = string
  default     = "alerts"
  description = "The alerts general folder name to attach all alerts to if no specific folder name set for alert rule item"
}

variable "group" {
  type        = string
  default     = "group"
  description = "The alerts general group name to attach all alerts to if no specific group set for alert rule item"
}

# Predefined annotations structure for all alerts
variable "annotations" {
  type = object({
    component    = optional(string, "")
    priority     = optional(string, "")
    owner        = optional(string, "")
    issue_phrase = optional(string, "")
    impact       = optional(string, "")
    runbook      = optional(string, "")
    provider     = optional(string, "")
    account      = optional(string, "")
    env          = optional(string, "")
    threshold    = optional(string, "")
    metric       = optional(string, "")
    summary      = optional(string, "")
  })
  default = {}
}

# Predefined labels structure for all alerts
variable "labels" {
  type = object({
    priority = optional(string, "P2")
    severity = optional(string, "warning")
    env      = optional(string, "")
  })
  default = {}
}

variable "alert_rules" {
  type = list(object({
    name                 = string                        # The name of the alert rule
    datasource           = string                        # Name of the datasource used for the alert
    no_data_state        = optional(string, "NoData")    # Describes what state to enter when the rule's query returns No Data
    exec_err_state       = optional(string, "Error")     # Describes what state to enter when the rule's query is invalid and the rule cannot be executed
    summary              = optional(string, null)        # Rule annotation as a summary, if not passed automatically generated based on data
    labels               = optional(map(any), {})        # Labels help to define matchers in notification policy to control where to send each alert. Can be any key-value pairs
    annotations          = optional(map(string), {})     # Annotations to set to the alert rule. Annotations will be used to customize the alert message in notifications template. Can be any key-value pairs
    group                = optional(string, null)        # Grafana alert rule group name, if this set null it will place rule into general var.group folder
    expr                 = optional(string, null)        # Full expression for the alert
    metric_name          = optional(string, "")          # Prometheus metric name which queries the data for the alert
    metric_function      = optional(string, "")          # Prometheus function used with metric for queries, like rate, sum etc.
    metric_interval      = optional(string, "")          # The time interval with using functions like rate
    settings_mode        = optional(string, "replaceNN") # The mode used in B block, possible values are Strict, replaceNN, dropNN
    settings_replaceWith = optional(number, 0)           # The value by which NaN results of the query will be replaced
    filters              = optional(any, null)           # Filters object to identify each service for alerting
    function             = optional(string, "mean")      # One of Reduce functions which will be used in B block for alerting
    equation             = optional(string, null)        # The equation in the math expression which compares B blocks value with a number and generates an alert if needed. Possible values: gt, lt, gte, lte, e. condition can replace equation/threshold pair
    threshold            = optional(number, null)        # The value against which B blocks are compared in the math expression, condition can replace equation/threshold pair
    pending_period       = optional(string, "0")         # Define for how long to wait to trigger alert if condition satisfies(how long it should last), for example valid values can be "5m", "30s" or "5m30s"
    condition            = optional(string, null)        # allows to define full custom compare condition on evaluated value of expression by name $B, condition can replace equation/threshold pair
  }))
  default     = []
  description = "This variable describes alert folders, groups and rules."
}
