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
# These annotations will be applied to all alerts and can be overridden by rule-specific annotations
# Values provided here will also be available in notification templates
variable "annotations" {
  type = object({
    component    = optional(string, "") # Component or service name (e.g., "kubernetes", "database", "api")
    owner        = optional(string, "") # Team or person responsible for the alert (e.g., "Platform Team", "DevOps")
    issue_phrase = optional(string, "") # Brief description of the issue type (e.g., "Service Issue", "Infrastructure Alert")
    impact       = optional(string, "") # Description of the impact (e.g., "Service degradation", "Complete outage")
    runbook      = optional(string, "") # URL to runbook or documentation for resolving the issue
    provider     = optional(string, "") # Cloud provider or platform (e.g., "AWS EKS", "GCP", "Azure")
    account      = optional(string, "") # Account or environment identifier (e.g., "production", "staging")
    threshold    = optional(string, "") # Threshold value that triggered the alert (e.g., "80%", "100ms")
    metric       = optional(string, "") # Metric name or type being monitored (e.g., "cpu-usage", "response-time")
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

variable "folder_name_uids" {
  type        = map(string)
  default     = {}
  description = "Map of folder names to folder UIDs. If provided, will be used instead of data sources"
}

variable "alert_rules" {
  type = list(object({
    name           = string                     # The name of the alert rule
    folder_name    = optional(string, null)     # The folder name for the alert rule, if not set it defaults to var.folder_name
    datasource     = string                     # Name of the datasource used for the alert
    no_data_state  = optional(string, "NoData") # Describes what state to enter when the rule's query returns No Data
    exec_err_state = optional(string, "Error")  # Describes what state to enter when the rule's query is invalid and the rule cannot be executed

    datasource_type      = optional(string, "prometheus") # The type of the datasource, possible values are prometheus or loki
    interval_ms          = optional(number, 1000)         # The interval in milliseconds for the alert rule
    labels               = optional(map(any), {})         # Labels help to define matchers in notification policy to control where to send each alert. Can be any key-value pairs
    annotations          = optional(map(string), {})      # Annotations to set to the alert rule. Annotations will be used to customize the alert message in notifications template. Can be any key-value pairs
    group                = optional(string, null)         # Grafana alert rule group name, if this set null it will place rule into general var.group folder
    expr                 = optional(string, null)         # Full expression for the alert
    metric_name          = optional(string, "")           # Prometheus metric name which queries the data for the alert
    metric_function      = optional(string, "")           # Prometheus function used with metric for queries, like rate, sum etc.
    metric_interval      = optional(string, "")           # The time interval with using functions like rate
    settings_mode        = optional(string, "replaceNN")  # The mode used in B block, possible values are Strict, replaceNN, dropNN
    settings_replaceWith = optional(number, 0)            # The value by which NaN results of the query will be replaced
    filters              = optional(any, null)            # Filters object to identify each service for alerting
    function             = optional(string, "mean")       # One of Reduce functions which will be used in B block for alerting
    equation             = optional(string, null)         # The equation in the math expression which compares B blocks value with a number and generates an alert if needed. Possible values: gt, lt, gte, lte, e. condition can replace equation/threshold pair
    threshold            = optional(number, null)         # The value against which B blocks are compared in the math expression, condition can replace equation/threshold pair
    pending_period       = optional(string, "0")          # Define for how long to wait to trigger alert if condition satisfies(how long it should last), for example valid values can be "5m", "30s" or "5m30s"
    condition            = optional(string, null)         # allows to define full custom compare condition on evaluated value of expression by name $B, condition can replace equation/threshold pair
  }))
  default     = []
  description = "This variable describes alert folders, groups and rules."
}
