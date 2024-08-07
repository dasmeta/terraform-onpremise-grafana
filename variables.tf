# dashboard variables
variable "name" {
  type        = string
  description = "Dashboard name"
}

variable "application_dashboard" {
  type = object({
    rows = optional(any, [])
    data_source = object({ # global/default datasource, TODO: create datasource inside the module
      uid  = string
      type = optional(string, "prometheus")
    })
    variables = optional(list(object({ # Allows to define variables to be used in dashboard
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
    })), [])
  })
  default = {
    rows        = [],
    data_source = null,
    variables   = []
  }
  description = "Dashboard for monitoring applications"
}

# alerting variables
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
  description = "This variable describes alert folders, groups and rules."
}

variable "slack_endpoints" {
  type = list(object({
    name                    = string                                                     # The name of the contact point.
    endpoint_url            = optional(string, "https://slack.com/api/chat.postMessage") # Use this to override the Slack API endpoint URL to send requests to.
    icon_emoji              = optional(string, "")                                       # The name of a Slack workspace emoji to use as the bot icon.
    icon_url                = optional(string, "")                                       # A URL of an image to use as the bot icon.
    recipient               = optional(string, null)                                     # Channel, private group, or IM channel (can be an encoded ID or a name) to send messages to.
    text                    = optional(string, "")                                       # Templated content of the message.
    title                   = optional(string, "")                                       # Templated title of the message.
    token                   = optional(string, "")                                       # A Slack API token,for sending messages directly without the webhook method.
    webhook_url             = optional(string, "")                                       # A Slack webhook URL,for sending messages via the webhook method.
    username                = optional(string, "")                                       # Username for the bot to use.
    disable_resolve_message = optional(bool, false)                                      # Whether to disable sending resolve messages.
  }))
  default     = []
  description = "Slack contact points list."
}

variable "opsgenie_endpoints" {
  type = list(object({
    name                    = string                                                 # The name of the contact point.
    api_key                 = string                                                 # The OpsGenie API key to use.
    auto_close              = optional(bool, false)                                  # Whether to auto-close alerts in OpsGenie when they resolve in the Alertmanager.
    message                 = optional(string, "")                                   # The templated content of the message.
    api_url                 = optional(string, "https://api.opsgenie.com/v2/alerts") # Allows customization of the OpsGenie API URL.
    disable_resolve_message = optional(bool, false)                                  # Whether to disable sending resolve messages.
  }))
  default     = []
  description = "OpsGenie contact points list."
}

variable "notifications" {
  type = object({
    contact_point   = optional(string, "Slack")                               # The default contact point to route all unmatched notifications to.
    group_by        = optional(list(string), ["grafana_folder", "alertname"]) # A list of alert labels to group alerts into notifications by.
    group_interval  = optional(string, "5m")                                  # Minimum time interval between two notifications for the same group.
    repeat_interval = optional(string, "4h")                                  # Minimum time interval for re-sending a notification if an alert is still firing.

    policy = optional(object({
      contact_point = optional(string, null) # The contact point to route notifications that match this rule to.
      continue      = optional(bool, false)  # Whether to continue matching subsequent rules if an alert matches the current rule. Otherwise, the rule will be 'consumed' by the first policy to match it.
      group_by      = optional(list(string), [])
      mute_timings  = optional(list(string), []) # A list of mute timing names to apply to alerts that match this policy.

      matcher = optional(object({
        label = optional(string, "priority") # The name of the label to match against.
        match = optional(string, "=")        # The operator to apply when matching values of the given label. Allowed operators are = for equality, != for negated equality, =~ for regex equality, and !~ for negated regex equality.
        value = optional(string, "P1")       # The label value to match against.
      }))
    }))
  })
  description = "Represents the configuration options for Grafana notification policies."
  default     = {}
}
