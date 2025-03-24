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

variable "alerts" {
  type = object({
    alert_interval_seconds = optional(number, 10) # The interval, in seconds, at which all rules in the group are evaluated. If a group contains many rules, the rules are evaluated sequentially
    disable_provenance     = optional(bool, true) # Allow modifying resources from other sources than Terraform or the Grafana API
    rules = optional(                             # Describes alert folders, groups and rules
      list(object({
        name                 = string                                    # The name of the alert rule
        no_data_state        = optional(string, "NoData")                # Describes what state to enter when the rule's query returns No Data
        exec_err_state       = optional(string, "Error")                 # Describes what state to enter when the rule's query is invalid and the rule cannot be executed
        summary              = optional(string, null)                    # Rule annotation as a summary, if not passed automatically generated based on data
        labels               = optional(map(any), { "priority" : "P1" }) # Labels help to define matchers in notification policy to control where to send each alert
        folder_name          = optional(string, "Main Alerts")           # Grafana folder name in which the rule will be created, the folder name used also as alert group name with suffix " Group"
        datasource           = string                                    # Name of the datasource used for the alert
        expr                 = optional(string, null)                    # Full expression for the alert
        metric_name          = optional(string, "")                      # Prometheus metric name which queries the data for the alert
        metric_function      = optional(string, "")                      # Prometheus function used with metric for queries, like rate, sum etc.
        metric_interval      = optional(string, "")                      # The time interval with using functions like rate
        settings_mode        = optional(string, "replaceNN")             # The mode used in B block, possible values are Strict, replaceNN, dropNN
        settings_replaceWith = optional(number, 0)                       # The value by which NaN results of the query will be replaced
        filters              = optional(any, null)                       # Filters object to identify each service for alerting
        function             = optional(string, "mean")                  # One of Reduce functions which will be used in B block for alerting
        equation             = string                                    # The equation in the math expression which compares B blocks value with a number and generates an alert if needed. Possible values: gt, lt, gte, lte, e
        threshold            = number                                    # The value against which B blocks are compared in the math expression
    })), [])
    contact_points = optional(object({
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
    }), null)
    notifications = optional(object({
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
    }), null)
  })

  default = {}
}

variable "grafana_configs" {
  type = object({
    enabled = optional(bool, true)
    resources = optional(object({
      request = optional(object({
        cpu = optional(string, "1")
        mem = optional(string, "2Gi")
      }), {})
      limit = optional(object({
        cpu = optional(string, "2")
        mem = optional(string, "3Gi")
      }), {})
    }), {})
    persistence = optional(object({
      enabled = optional(bool, true)
      type    = optional(string, "pvc")
      size    = optional(string, "10Gi")
    }), {})
    ingress_configs = optional(object({
      annotations = optional(map(string),
        {
          "kubernetes.io/ingress.class"                = "alb"
          "alb.ingress.kubernetes.io/scheme"           = "internet-facing"
          "alb.ingress.kubernetes.io/target-type"      = "ip"
          "alb.ingress.kubernetes.io/listen-ports"     = "[{\"HTTP\": 80}]"
          "alb.ingress.kubernetes.io/group.name"       = "monitoring"
          "alb.ingress.kubernetes.io/healthcheck-path" = "/api/health"
        }
      )
      hosts     = optional(list(string), ["grafana.example.com"])
      path      = optional(string, "/")
      path_type = optional(string, "Prefix")
    }))
    prometheus_url = optional(string, "http://prometheus-operated.monitoring.svc.cluster.local:9090")

    replicas  = optional(number, 1)
    image_tag = optional(string, "11.4.2")
  })

  description = "Values to construct the values file for Grafana Helm chart"
  default     = {}
}

variable "prometheus_configs" {
  type = object({
    enabled        = optional(bool, true)
    retention_days = optional(string, "15d")
    storage_class  = optional(string, "efs-sc-root")
    storage_size   = optional(string, "10Gi")
    resources = optional(object({
      request = optional(object({
        cpu = optional(string, "500m")
        mem = optional(string, "500Mi")
      }), {})
      limit = optional(object({
        cpu = optional(string, "1")
        mem = optional(string, "1Gi")
      }), {})
    }), {})
    enable_alertmanager = optional(bool, true)
  })
  description = "values to be used as prometheus's chart values"
  default     = {}
}

variable "grafana_admin_password" {
  type        = string
  description = "grafana admin user password"
  default     = ""
}

variable "aws_region" {
  type    = string
  default = "eu-central-1"
}
