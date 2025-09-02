variable "alert_interval_seconds" {
  type        = number
  default     = 10
  description = "The interval, in seconds, at which all rules in the group are evaluated. If a group contains many rules, the rules are evaluated sequentially."
}

variable "disable_provenance" {
  type        = bool
  default     = true
  description = "Allow modifying the resources from other sources than Terraform or the Grafana API"
}

variable "create_folder" {
  type        = bool
  default     = true
  description = "Whether to create one general group folder for all alerts"
}

variable "folder_name" {
  type        = string
  default     = "alerts"
  description = "The alerts general group folder name to attach all alerts to if no specific folder name set for alert rule item"
}

variable "group" {
  type        = string
  default     = "group"
  description = "The alerts general group name to attach all alerts to if no specific group set for alert rule item"
}

variable "enable_message_template" {
  type        = bool
  default     = true
  description = "Whether to enable the message template for the alerts"
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

variable "rules" {
  type = list(object({
    name           = string                     # The name of the alert rule
    no_data_state  = optional(string, "NoData") # Describes what state to enter when the rule's query returns No Data
    exec_err_state = optional(string, "Error")  # Describes what state to enter when the rule's query is invalid and the rule cannot be executed

    labels               = optional(map(any), {})        # Labels help to define matchers in notification policy to control where to send each alert. Can be any key-value pairs
    annotations          = optional(map(string), {})     # Annotations to set to the alert rule. Annotations will be used to customize the alert message in notifications template. Can be any key-value pairs
    group                = optional(string, null)        # Grafana group name in which the rule will be created/grouped
    datasource           = string                        # Name of the datasource used for the alert
    expr                 = optional(string, null)        # Full expression for the alert
    metric_name          = optional(string, "")          # Prometheus metric name which queries the data for the alert
    metric_function      = optional(string, "")          # Prometheus function used with metric for queries, like rate, sum etc.
    metric_interval      = optional(string, "")          # The time interval with using functions like rate
    settings_mode        = optional(string, "replaceNN") # The mode used in B block, possible values are Strict, replaceNN, dropNN
    settings_replaceWith = optional(number, 0)           # The value by which NaN results of the query will be replaced
    filters              = optional(any, null)           # Filters object to identify each service for alerting
    function             = optional(string, "mean")      # One of Reduce functions which will be used in B block for alerting
    equation             = string                        # The equation in the math expression which compares B blocks value with a number and generates an alert if needed. Possible values: gt, lt, gte, lte, e
    threshold            = number                        # The value against which B blocks are compared in the math expression
  }))
  default     = null
  description = "This variable describes alert folders, groups and rules."
}

variable "contact_points" {
  type = object({
    slack = optional(list(object({                                                         # Slack contact points list
      name                    = string                                                     # The name of the contact point
      endpoint_url            = optional(string, "https://slack.com/api/chat.postMessage") # Use this to override the Slack API endpoint URL to send requests to
      icon_emoji              = optional(string, "")                                       # The name of a Slack workspace emoji to use as the bot icon
      icon_url                = optional(string, "")                                       # A URL of an image to use as the bot icon
      recipient               = optional(string, null)                                     # Channel, private group, or IM channel (can be an encoded ID or a name) to send messages to
      text                    = optional(string, "")                                       # Templated content of the message
      title                   = optional(string, "")                                       # Templated title of the message
      token                   = optional(string, "")                                       # A Slack API token,for sending messages directly without the webhook method
      webhook_url             = optional(string, "")                                       # A Slack webhook URL,for sending messages via the webhook method
      username                = optional(string, "")                                       # Username for the bot to use
      disable_resolve_message = optional(bool, false)                                      # Whether to disable sending resolve messages
    })), [])
    opsgenie = optional(list(object({                                                  # OpsGenie contact points list
      name                    = string                                                 # The name of the contact point
      api_key                 = string                                                 # The OpsGenie API key to use
      auto_close              = optional(bool, false)                                  # Whether to auto-close alerts in OpsGenie when they resolve in the Alert manager
      message                 = optional(string, "")                                   # The templated content of the message
      api_url                 = optional(string, "https://api.opsgenie.com/v2/alerts") # Allows customization of the OpsGenie API URL
      disable_resolve_message = optional(bool, false)                                  # Whether to disable sending resolve messages
    })), [])
    teams = optional(list(object({                    # Teams contact points list
      name                    = string                # The name of the contact point
      url                     = string                # The MS Teams Webhook URL to use
      message                 = optional(string, "")  # The templated content of the message
      disable_resolve_message = optional(bool, false) # Whether to disable sending resolve messages
      section_title           = optional(string, "")  # The templated subtitle for each message section.
      title                   = optional(string, "")  # The templated title of the message
    })), [])
    webhook = optional(list(object({                     # Contact points that send notifications to an arbitrary webhook, using the Prometheus webhook format
      name                      = string                 # The name of the contact point
      url                       = string                 # The URL to send webhook requests to
      authorization_credentials = optional(string, null) # Allows a custom authorization scheme - attaches an auth header with this value. Do not use in conjunction with basic auth parameters
      authorization_scheme      = optional(string, null) # Allows a custom authorization scheme - attaches an auth header with this name. Do not use in conjunction with basic auth parameters
      basic_auth_password       = optional(string, null) # The password component of the basic auth credentials to use
      basic_auth_user           = optional(string, null) # The username component of the basic auth credentials to use
      disable_resolve_message   = optional(bool, false)  # Whether to disable sending resolve messages. Defaults to
      settings                  = optional(any, null)    # Additional custom properties to attach to the notifier
    })), [])
  })
  default     = null
  description = "Grafana contact points configs."
}


variable "notifications" {
  type = object({
    contact_point   = optional(string, "Slack")       # The default contact point to route all unmatched notifications to
    group_by        = optional(list(string), ["..."]) # A list of alert labels to group alerts into notifications by
    group_interval  = optional(string, "5m")          # Minimum time interval between two notifications for the same group
    repeat_interval = optional(string, "4h")          # Minimum time interval for re-sending a notification if an alert is still firing

    mute_timing = optional(object({                  # Mute timing config, which will be applied on all policies
      name = optional(string, "Default mute timing") # the name of mute timing
      intervals = optional(list(object({             # the mute timing interval configs
        weekdays      = optional(string, null)
        days_of_month = optional(string, null)
        months        = optional(string, null)
        years         = optional(string, null)
        location      = optional(string, null)
        times = optional(object({
          start = optional(string, "00:00")
          end   = optional(string, "24:59")
        }), null)
      })), [])
    }), null)

    policies = optional(list(object({
      contact_point = optional(string, null) # The contact point to route notifications that match this rule to
      continue      = optional(bool, true)   # Whether to continue matching subsequent rules if an alert matches the current rule. Otherwise, the rule will be 'consumed' by the first policy to match it
      group_by      = optional(list(string), ["..."])

      matchers = optional(list(object({
        label = optional(string, "priority") # The name of the label to match against
        match = optional(string, "=")        # The operator to apply when matching values of the given label. Allowed operators are = for equality, != for negated equality, =~ for regex equality, and !~ for negated regex equality
        value = optional(string, "P1")       # The label value to match against
      })), [])
      policies = optional(list(object({ # sub-policies(there is also possibility to implement also ability for sub.sub.sub-policies, but for not seems existing configs are enough)
        contact_point = optional(string, null)
        continue      = optional(bool, true)
        group_by      = optional(list(string), ["..."])
        mute_timings  = optional(list(string), [])

        matchers = optional(list(object({
          label = optional(string, "priority")
          match = optional(string, "=")
          value = optional(string, "P1")
        })), [])
      })), [])
    })), [])
  })
  description = "Represents the configuration options for Grafana notification policies. This config is global for grafana and overrides existing configs."
  default     = {}
}
