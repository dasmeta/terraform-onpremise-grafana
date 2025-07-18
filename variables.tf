variable "cluster_name" {
  type        = string
  description = "name of the eks cluster"
}

variable "name" {
  type        = string
  description = "Dashboard name"
}

variable "grafana_admin_password" {
  type        = string
  description = "grafana admin user password"
  default     = ""
}

variable "namespace" {
  type    = string
  default = "monitoring"
}

variable "aws_region" {
  type    = string
  default = "eu-central-1"
}

variable "application_dashboard" {
  type = object({
    folder_name = optional(string, "application-dashboard") # the folder name for dashboard
    rows        = optional(any, [])
    data_source = optional(object({
      uid  = optional(string, "prometheus")
      type = optional(string, "prometheus")
    }), {})
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
    alerts = optional(any, { enabled = true }) # Allows to configure globally dashboard block/(sla|ingress|service) blocks/widgets related alerts
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
    alert_interval_seconds = optional(number, 10)       # The interval, in seconds, at which all rules in the group are evaluated. If a group contains many rules, the rules are evaluated sequentially
    disable_provenance     = optional(bool, true)       # Allow modifying resources from other sources than Terraform or the Grafana API
    create_folder          = optional(bool, false)      # whether to create folder to place app dashboard and alerts there, if folder with provided name exist already no need to create it again
    folder_name            = optional(string, null)     # The folder name for dashboard, if not set it defaults to var.application_dashboard.folder_name
    group                  = optional(string, "custom") # The alerts general group name
    rules = optional(
      list(object({                                                      # Describes custom alert rules
        name                 = string                                    # The name of the alert rule
        no_data_state        = optional(string, "NoData")                # Describes what state to enter when the rule's query returns No Data
        exec_err_state       = optional(string, "Error")                 # Describes what state to enter when the rule's query is invalid and the rule cannot be executed
        summary              = optional(string, null)                    # Rule annotation as a summary, if not passed automatically generated based on data
        labels               = optional(map(any), { "priority" : "P1" }) # Labels help to define matchers in notification policy to control where to send each alert
        group                = optional(string, "custom")                # Grafana alert group name in which the rule will be created/grouped
        datasource           = string                                    # Name of the datasource used for the alert
        expr                 = optional(string, null)                    # Full expression for the alert
        metric_name          = optional(string, "")                      # Prometheus metric name which queries the data for the alert
        metric_function      = optional(string, "")                      # Prometheus function used with metric for queries, like rate, sum etc.
        metric_interval      = optional(string, "")                      # The time interval with using functions like rate
        settings_mode        = optional(string, "replaceNN")             # The mode used in B block, possible values are Strict, replaceNN, dropNN
        settings_replaceWith = optional(number, 0)                       # The value by which NaN results of the query will be replaced
        filters              = optional(any, {})                         # Filters object to identify each service for alerting
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

  default     = {}
  description = "Alerting configurations, NOTE: we have also option to create alert rules attached to dashboard widget blocks"
}

variable "grafana" {
  type = object({
    enabled       = optional(bool, true)
    chart_version = optional(string, "9.2.9")
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
    database = optional(object({           # configure external(or in helm created) database base storing/persisting grafana data
      enabled       = optional(bool, true) # whether database based persistence is enabled
      create        = optional(bool, true) # whether to create mysql databases or use already existing database
      name          = optional(string, "grafana")
      type          = optional(string, "mysql") # when we set external database we can set any sql compatible one like postgresql or ms sql, but when we create database it supports only mysql and changing this field do not affect
      host          = optional(string, null)    # it will set right host for grafana mysql in case create=true
      user          = optional(string, "grafana")
      password      = optional(string, null)    # if not set it will use var.grafana_admin_password
      root_password = optional(string, null)    # if not set it will use var.grafana_admin_password
      persistence = optional(object({           # allows to configure created(when database.create=true) mysql databases storage/persistence configs
        enabled      = optional(bool, true)     # whether to have created in k8s mysql database with persistence
        size         = optional(string, "20Gi") # the size of primary persistent volume of mysql when creating it
        storageClass = optional(string, "")     # if set "" it takes the default storage class of k8s
      }), {})
      storage_size = optional(string, "20Gi")           # the size of primary persistent volume of mysql when creating it
      extra_flags  = optional(string, "--skip-log-bin") # allows to set extra flags(whitespace separated) on grafana mysql primary instance, we have by default skip-log-bin flag set to disable bin-logs which overload mysql disc and/but we do not use multi replica mysql here
    }), {})
    persistence = optional(object({ # configure pvc base storing/persisting grafana data(it uses sqlite DB in this mode), NOTE: we use mysql database for data storage by default and no need to enable persistence if DB is set, so that we have persistence disable here by default
      enabled       = optional(bool, false)
      type          = optional(string, "pvc")
      size          = optional(string, "20Gi")
      storage_class = optional(string, "gp2")
    }), {})
    ingress = optional(object({
      annotations     = optional(map(string), {})
      hosts           = optional(list(string), ["grafana.example.com"])
      path            = optional(string, "/")
      path_type       = optional(string, "Prefix")
      type            = optional(string, "alb")
      public          = optional(bool, true)
      tls_enabled     = optional(bool, true)
      alb_certificate = optional(string, "")
    }))

    redundancy = optional(object({
      enabled                  = optional(bool, false)
      max_replicas             = optional(number, 4)
      min_replicas             = optional(number, 1)
      redundancy_storage_class = optional(string, "efs-sc-root")
    }), {})

    datasources = optional(list(map(any))) # a list of grafana datasource configurations. Based on the type of the datasource the module will fill in the missing configuration for some supported datasources. Mandatory are name and type fields
    trace_log_mapping = optional(object({
      enabled       = optional(bool, false)
      trace_pattern = optional(string, "trace_id=(\\w+)")
    }), {})

    replicas = optional(number, 1)
  })

  description = "Values to construct the values file for Grafana Helm chart"
  default     = {}
}

variable "prometheus" {
  type = object({
    enabled        = optional(bool, true)
    chart_version  = optional(string, "75.8.0")
    retention_days = optional(string, "15d")
    storage_class  = optional(string, "gp2")
    storage_size   = optional(string, "100Gi")
    access_modes   = optional(list(string), ["ReadWriteOnce"])
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
    replicas            = optional(number, 2)
    enable_alertmanager = optional(bool, true)
  })
  description = "values to be used as prometheus's chart values"
  default     = {}
}

variable "tempo" {
  type = object({
    enabled                = optional(bool, false)
    chart_version          = optional(string, "1.20.0")
    tempo_role_arn         = optional(string, "")
    storage_backend        = optional(string, "s3") # "local" or "s3"
    bucket_name            = optional(string)
    enable_service_monitor = optional(bool, true)
    oidc_provider_arn      = optional(string, "")

    metrics_generator = optional(object({
      enabled    = optional(bool, true)
      remote_url = optional(string, "http://prometheus-kube-prometheus-prometheus.monitoring.svc.cluster.local:9090/api/v1/write")
    }))

    persistence = optional(object({
      enabled       = optional(bool, true)
      size          = optional(string, "20Gi")
      storage_class = optional(string, "gp2")
    }), {})

  })
  description = "confgis for tempo deployment"
  default     = {}
}

variable "loki" {
  type = object({
    enabled       = optional(bool, false)
    chart_version = optional(string, "6.30.1")
    loki = optional(object({
      url            = optional(string, "")
      volume_enabled = optional(bool, true)
      send_logs_s3 = optional(object({
        enable       = optional(bool, true)
        bucket_name  = optional(string, "")
        aws_role_arn = optional(string, "")
      }), {})
      service_account = optional(object({
        enable      = optional(bool, true)
        name        = optional(string, "loki")
        annotations = optional(map(string), {})
      }), {})
      persistence = optional(object({
        enabled       = optional(bool, true)
        size          = optional(string, "20Gi")
        storage_class = optional(string, "gp2")
        access_mode   = optional(string, "ReadWriteOnce")
      }), {})
      schema_configs = optional(list(object({
        from         = optional(string, "2025-01-01") # defines starting at which date this storage schema will be applied
        object_store = optional(string, "s3")
        store        = optional(string, "tsdb")
        schema       = optional(string, "v13")
        index = optional(object({
          prefix = optional(string, "index_")
          period = optional(string, "24h")
        }), {})
      })), [{}])
      storage          = optional(map(any), {})
      replicas         = optional(number, 1)
      retention_period = optional(string, "168h")
      resources = optional(object({
        request = optional(object({
          cpu = optional(string, "200m")
          mem = optional(string, "250Mi")
        }), {})
        limit = optional(object({
          cpu = optional(string, "400m")
          mem = optional(string, "500Mi")
        }), {})
      }), {})
    }), {})
    promtail = optional(object({
      enabled               = optional(bool, true)
      log_level             = optional(string, "info")
      server_port           = optional(string, "3101")
      clients               = optional(list(string), [])
      log_format            = optional(string, "logfmt")
      extra_scrape_configs  = optional(list(any), [])
      extra_label_configs   = optional(list(map(string)), [])
      extra_pipeline_stages = optional(any, [])
      ignored_containers    = optional(list(string), [])
      ignored_namespaces    = optional(list(string), [])
    }), {})
  })
  description = "Values to pass to loki helm chart"
  default     = {}
}

variable "dashboards_json_files" {
  type        = list(string)
  default     = []
  description = "Json definition of dashboard. For quickly provisioning the dashboards"
}
