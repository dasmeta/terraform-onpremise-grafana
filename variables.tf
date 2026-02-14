variable "grafana_admin_password" {
  type        = string
  description = "grafana admin user password"
  default     = ""
}

variable "namespace" {
  type    = string
  default = "monitoring"
}

variable "skip_folder_creation" {
  type        = bool
  default     = false
  description = "If true, folders are created in submodules. If false, folders are created centrally."
}

variable "application_dashboard" {
  type = list(object({
    name        = string
    defaults    = optional(any, {})                         # allows to pass/override some general defaults for datasources and widgets
    folder_name = optional(string, "application-dashboard") # the folder name for dashboard
    namespace   = optional(string, "prod")
    rows        = optional(any, [])
    data_source = optional(object({
      uid  = optional(string, "prometheus")
      type = optional(string, "prometheus")
    }), {})
    loki_datasource_uid = optional(string, "loki") # the default datasource that will be used on loki/logs related widgets/blocks, "block/service" block allows to pass custom value for this variable
    variables = optional(list(object({             # Allows to define variables to be used in dashboard
      name             = string
      type             = optional(string, "custom")
      hide             = optional(number, 0)
      includeAll       = optional(bool, false)
      multi            = optional(bool, false)
      query            = optional(string, "")
      queryValue       = optional(string, "")
      skipUrlSync      = optional(bool, false)
      allowCustomValue = optional(bool, false)
      options = optional(list(object({
        selected = optional(bool, false)
        value    = string
        text     = optional(string, null)
      })), [])
    })), [])
    alerts = optional(any, { enabled = true }) # Allows to configure globally dashboard block/(sla|ingress|service) blocks/widgets related alerts
  }))
  default     = []
  description = "Dashboard for monitoring applications"
}

variable "alerts" {
  type = object({
    alert_interval_seconds  = optional(number, 10)       # The interval, in seconds, at which all rules in the group are evaluated. If a group contains many rules, the rules are evaluated sequentially
    disable_provenance      = optional(bool, true)       # Allow modifying resources from other sources than Terraform or the Grafana API
    create_folder           = optional(bool, false)      # whether to create folder to place app dashboard and alerts there, if folder with provided name exist already no need to create it again
    folder_name             = optional(string, null)     # The folder name for dashboard, if not set it defaults to var.application_dashboard.folder_name
    group                   = optional(string, "custom") # The alerts general group name
    enable_message_template = optional(bool, true)       # Whether to enable the message template for the alerts
    # Predefined annotations structure for all alerts
    # These annotations will be applied to all alerts and can be overridden by rule-specific annotations
    # Values provided here will also be available in notification templates
    annotations = optional(object({
      component    = optional(string, "") # Component or service name (e.g., "kubernetes", "database", "api")
      owner        = optional(string, "") # Team or person responsible for the alert (e.g., "Platform Team", "DevOps")
      issue_phrase = optional(string, "") # Brief description of the issue type (e.g., "Service Issue", "Infrastructure Alert")
      impact       = optional(string, "") # Description of the impact (e.g., "Service degradation", "Complete outage")
      runbook      = optional(string, "") # URL to runbook or documentation for resolving the issue
      provider     = optional(string, "") # Cloud provider or platform (e.g., "AWS EKS", "GCP", "Azure")
      account      = optional(string, "") # Account or environment identifier (e.g., "production", "staging")
      threshold    = optional(string, "") # Threshold value that triggered the alert (e.g., "80%", "100ms")
      metric       = optional(string, "") # Metric name or type being monitored (e.g., "cpu-usage", "response-time")
    }), {})

    # Predefined labels structure for all alerts
    labels = optional(object({
      priority = optional(string, "P2")
      severity = optional(string, "warning")
      env      = optional(string, "")
      team     = optional(string, "")
    }), {})
    rules = optional(
      list(object({                                 # Describes custom alert rules
        name           = string                     # The name of the alert rule
        folder_name    = optional(string, null)     # The folder name for the alert rule, if not set it defaults to var.alerts.folder_name
        no_data_state  = optional(string, "NoData") # Describes what state to enter when the rule's query returns No Data
        exec_err_state = optional(string, "Error")  # Describes what state to enter when the rule's query is invalid and the rule cannot be executed

        labels               = optional(map(any), {})         # Labels help to define matchers in notification policy to control where to send each alert. Can be any key-value pairs
        annotations          = optional(map(string), {})      # Annotations to set to the alert rule. Annotations will be used to customize the alert message in notifications template. Can be any key-value pairs
        group                = optional(string, "custom")     # Grafana alert group name in which the rule will be created/grouped
        datasource           = string                         # Name of the datasource used for the alert
        datasource_type      = optional(string, "prometheus") # The type of the datasource, possible values are prometheus or loki
        interval_ms          = optional(number, 1000)         # The interval in milliseconds for the alert rule
        expr                 = optional(string, null)         # Full expression for the alert
        metric_name          = optional(string, "")           # Prometheus metric name which queries the data for the alert
        metric_function      = optional(string, "")           # Prometheus function used with metric for queries, like rate, sum etc.
        metric_interval      = optional(string, "")           # The time interval with using functions like rate
        settings_mode        = optional(string, "replaceNN")  # The mode used in B block, possible values are Strict, replaceNN, dropNN
        settings_replaceWith = optional(number, 0)            # The value by which NaN results of the query will be replaced
        filters              = optional(any, {})              # Filters object to identify each service for alerting
        function             = optional(string, "mean")       # One of Reduce functions which will be used in B block for alerting
        equation             = string                         # The equation in the math expression which compares B blocks value with a number and generates an alert if needed. Possible values: gt, lt, gte, lte, e
        pending_period       = optional(string, "0")          # Define for how long to wait to trigger alert if condition satisfies(how long it should last), for example valid values can be "5m", "30s" or "5m30s"
        threshold            = number                         # The value against which B blocks are compared in the math expression
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
    enabled          = optional(bool, true)
    namespace        = optional(string, null) # the namespace fallbacks to var.namespace if not specified
    create_namespace = optional(bool, true)   # whether create namespace if not exist
    chart_version    = optional(string, "9.2.9")
    release_name     = optional(string, "grafana")
    resources = optional(object({
      requests = optional(object({
        cpu    = optional(string, "1")
        memory = optional(string, "2Gi")
      }), {})
      limits = optional(object({
        cpu    = optional(string, "2")
        memory = optional(string, "3Gi")
      }), {})
    }), {})
    database = optional(object({           # configure external(or in helm created) database base storing/persisting grafana data
      enabled       = optional(bool, true) # whether database based persistence is enabled
      create        = optional(bool, true) # whether to create mysql databases or use already existing database
      name          = optional(string, "grafana")
      type          = optional(string, "mysql") # when we set external database we can set any sql compatible one like postgresql or ms sql, but when we create database it supports only mysql and changing this field do not affect
      host          = optional(string, null)    # it will set right host for grafana mysql in case create=true
      user          = optional(string, "grafana")
      password      = optional(string, null)     # if not set it will use var.grafana_admin_password
      root_password = optional(string, null)     # if not set it will use var.grafana_admin_password
      persistence = optional(object({            # allows to configure created(when database.create=true) mysql databases storage/persistence configs
        enabled       = optional(bool, true)     # whether to have created in k8s mysql database with persistence
        size          = optional(string, "20Gi") # the size of primary persistent volume of mysql when creating it
        storage_class = optional(string, "")     # default storage class for the mysql database
      }), {})
      # the size of primary persistent volume of mysql when creating it
      extra_flags = optional(string, "--skip-log-bin") # allows to set extra flags(whitespace separated) on grafana mysql primary instance, we have by default skip-log-bin flag set to disable bin-logs which overload mysql disc and/but we do not use multi replica mysql here
    }), {})
    persistence = optional(object({ # configure pvc base storing/persisting grafana data(it uses sqlite DB in this mode), NOTE: we use mysql database for data storage by default and no need to enable persistence if DB is set, so that we have persistence disable here by default
      enabled       = optional(bool, false)
      type          = optional(string, "pvc")
      size          = optional(string, "20Gi")
      storage_class = optional(string, "")
    }), {})
    ingress = optional(object({
      annotations = optional(map(string), {})
      hosts       = optional(list(string), ["grafana.example.com"])
      path        = optional(string, "/")
      path_type   = optional(string, "Prefix")
      type        = optional(string, "nginx")
      public      = optional(bool, true)
      tls_enabled = optional(bool, true)
    }))
    service_account = optional(object({
      name        = optional(string, "grafana")
      enable      = optional(bool, true)
      annotations = optional(map(string), {})
    }), {})
    redundancy = optional(object({
      enabled      = optional(bool, false)
      max_replicas = optional(number, 4)
      min_replicas = optional(number, 1)
    }), {})

    datasources = optional(list(map(any))) # a list of grafana datasource configurations. Based on the type of the datasource the module will fill in the missing configuration for some supported datasources. Mandatory are name and type fields
    trace_log_mapping = optional(object({
      enabled       = optional(bool, false)
      trace_pattern = optional(string, "trace_id=(\\w+)")
    }), {})

    replicas            = optional(number, 1)
    extra_configs       = optional(any, {}) # allows to pass extra/custom configs to grafana helm chart, this configs will deep-merged with all generated internal configs and can override the default set ones. All available options can be found in for the specified chart version here: https://artifacthub.io/packages/helm/grafana/grafana?modal=values
    mysql_extra_configs = optional(any, {}) # allows to pass extra/custom configs to grafana-mysql created helm chart, this configs will deep-merged with all generated internal configs and can override the default set ones. All available options can be found in for the specified chart version here: https://artifacthub.io/packages/helm/bitnami/mysql?modal=values
    sso_settings = optional(map(object({    # SSO settings for Grafana. Supports OAuth2 providers (gitlab, github, google, azuread, okta, generic_oauth), SAML, and LDAP. The map key should be the provider name, NOTE: that multiple providers can be passed but if a user(email is identifier) got logged in by using one of the providers it may fail to login by using another provider.
      oauth2_settings = optional(object({
        name                       = string                # Display name shown on the login page as "Sign in with...". This is different from the provider name (which is the map key like "gitlab", "github", "google", "azuread", "okta", "generic_oauth", "saml", "ldap"). The provider name determines the OAuth2 endpoints, while this name is just the label shown to users (e.g., "GitLab", "GitHub", "Company SSO")
        client_id                  = string                # The client ID of your OAuth2 application
        client_secret              = string                # The client secret of your OAuth2 application
        auth_url                   = optional(string)      # OAuth2 authorization URL (not needed for built-in providers: gitlab, github, google, azuread, okta)
        token_url                  = optional(string)      # OAuth2 token URL (not needed for built-in providers: gitlab, github, google, azuread, okta)
        api_url                    = optional(string)      # OAuth2 API URL (not needed for built-in providers: gitlab, github, google, azuread, okta)
        allow_sign_up              = optional(bool, true)  # If true, new users can automatically create Grafana accounts on first login
        auto_login                 = optional(bool, false) # If true, automatically logs in users, skipping the login screen
        scopes                     = optional(string)      # Comma or space-separated list of OAuth2 scopes (e.g., "openid email profile" for GitLab)
        allowed_groups             = optional(string)      # Comma or space-separated list of GitLab group names (e.g., "org-1", "org-2", "dev-team"). In GitLab, "group" is the organizational unit (like "organization" in GitHub). User must be a MEMBER of at least one of these groups to log in. This checks GROUP MEMBERSHIP, NOT the user's role within the group (Maintainer/Developer/Guest). For GitHub: organization names. Requires OAuth scope "read_api" for GitLab or "read:org" for GitHub.
        allowed_domains            = optional(string)      # Comma or space-separated list of email domains. User must belong to at least one domain to log in. For GitHub: requires "user:email" scope and the user's email must be verified in GitHub. Email privacy settings in GitHub may prevent this from working.
        role_attribute_path        = optional(string)      # JSONPath expression to map OAuth provider groups to Grafana roles. Checks if user is a member of SPECIFIC groups (not org names). Example: "contains(groups[*], 'grafana-admin') && 'Admin' || contains(groups[*], 'grafana-editor') && 'Editor' || 'Viewer'" means: if user is in "grafana-admin" group → Admin role, if in "grafana-editor" group → Editor role, otherwise → Viewer. These groups (e.g., "grafana-admin", "grafana-editor") must exist in your GitLab/GitHub and users must be added to them. Different from allowed_groups which checks org membership.
        role_attribute_strict      = optional(bool)        # If true, requires role_attribute_path to be set and valid
        allow_assign_grafana_admin = optional(bool)        # If true, allows assigning Grafana Admin role via OAuth
        skip_org_role_sync         = optional(bool)        # If true, skips syncing organization roles from OAuth
      }))
      saml_settings = optional(object({
        name             = string                # Display name shown on the login page as "Sign in with..."
        idp_metadata_url = optional(string)      # URL to the SAML Identity Provider metadata XML file
        allow_sign_up    = optional(bool, true)  # If true, new users can automatically create Grafana accounts on first login
        auto_login       = optional(bool, false) # If true, automatically logs in users, skipping the login screen
      }))
      ldap_settings = optional(object({
        allow_sign_up = optional(bool, true) # If true, new users can automatically create Grafana accounts on first login
        config = object({
          servers = list(object({
            host            = string                # LDAP server hostname or IP address
            port            = optional(number, 389) # LDAP server port (default: 389 for LDAP, 636 for LDAPS)
            search_base_dns = list(string)          # Base DNs to search for users (e.g., ["ou=users,dc=example,dc=com"])
            search_filter   = string                # LDAP search filter to find users (e.g., "(cn=%s)" or "(uid=%s)")
          }))
        })
      }))
    })), {})
  })

  description = "Values to construct the values file for Grafana Helm chart"
  default     = {}
}

variable "prometheus" {
  type = object({
    enabled          = optional(bool, true)
    namespace        = optional(string, null) # the namespace fallbacks to var.namespace if not specified
    create_namespace = optional(bool, true)   # whether create namespace if not exist
    release_name     = optional(string, "prometheus")
    chart_version    = optional(string, "75.8.0")
    retention_days   = optional(string, "15d")
    storage_class    = optional(string, "")
    storage_size     = optional(string, "100Gi")
    access_modes     = optional(list(string), ["ReadWriteOnce"])
    resources = optional(object({
      requests = optional(object({
        cpu    = optional(string, "1")
        memory = optional(string, "2500Mi")
      }), {})
      limits = optional(object({
        cpu    = optional(string, "2")
        memory = optional(string, "3Gi")
      }), {})
    }), {})
    replicas                     = optional(number, 1)
    enable_alertmanager          = optional(bool, true)  # allows to enable alertmanager. By default, we enable it.
    scrape_helm_chart_components = optional(bool, false) # enable scraping all servicemonitors. The chart by default has disabled scraping all servicemonitors. https://artifacthub.io/packages/helm/prometheus-community/kube-prometheus-stack#prometheus-io-scrape
    additional_scrape_configs    = optional(any, [])     # allows to specify additional scrape configs for prometheus. Example can be found in tests/prometheus-additional-scrape-configs/1-example.tf
    ingress = optional(object({
      enabled     = optional(bool, false)
      type        = optional(string, "nginx")
      public      = optional(bool, true)
      tls_enabled = optional(bool, true)

      annotations = optional(map(string), {})
      hosts       = optional(list(string), ["prometheus.example.com"])
      path        = optional(list(string), ["/"])
      path_type   = optional(string, "Prefix")
    }), {})
    kubelet_metrics = optional(list(string), ["container_cpu_.*", "container_memory_.*", "kube_pod_container_status_.*",
      "kube_pod_container_resource_.*", "container_network_.*", "kube_pod_resource_limit",
      "kube_pod_resource_request", "pod_cpu_usage_seconds_total", "pod_memory_usage_bytes",
      "kubelet_volume_stats.*", "volume_operation_total_seconds.*", "container_fs_.*"]
    )
    additional_args = optional(list(object({
      name  = string
      value = string
      })), [
      {
        name  = "query.max-concurrency"
        value = "64"
      },
      {
        name  = "query.timeout"
        value = "2m"
      },
      {
        name  = "query.max-samples"
        value = "75000000"
      }
    ])
    extra_configs = optional(any, {}) # allows to pass extra/custom configs to prometheus helm chart, this configs will deep-merged with all generated internal configs and can override the default set ones. All available options can be found in for the specified chart version here: https://artifacthub.io/packages/helm/prometheus-community/prometheus?modal=values
  })
  description = "values to be used as prometheus's chart values"
  default     = {}
}

variable "tempo" {
  type = object({
    enabled          = optional(bool, false)
    namespace        = optional(string, null) # the namespace fallbacks to var.namespace if not specified
    create_namespace = optional(bool, true)   # whether create namespace if not exist
    chart_version    = optional(string, "1.23.3")
    release_name     = optional(string, "tempo")
    service_account = optional(object({
      name        = optional(string, "tempo")
      annotations = optional(map(string), {})
    }), {})
    storage = optional(object({
      backend = optional(string, "local")
      backend_configuration = optional(map(any), {
        local = { path = "/var/tempo/traces" },
        wal   = { path = "/var/tempo/wal" }
      })
    }), {})
    enable_service_monitor = optional(bool, true)
    oidc_provider_arn      = optional(string, "")

    metrics_generator = optional(object({
      enabled    = optional(bool, true)
      remote_url = optional(string, "http://prometheus-kube-prometheus-prometheus.monitoring.svc.cluster.local:9090/api/v1/write")
    }))

    persistence = optional(object({
      enabled       = optional(bool, true)
      size          = optional(string, "20Gi")
      storage_class = optional(string, "")
    }), {})
    extra_configs = optional(any, {}) # allows to pass extra/custom configs to tempo helm chart, this configs will deep-merged with all generated internal configs and can override the default set ones. All available options can be found in for the specified chart version here: https://artifacthub.io/packages/helm/grafana/tempo?modal=values
  })
  description = "Configs for tempo deployment"
  default     = {}
}

variable "loki_stack" {
  type = object({
    enabled          = optional(bool, false)  # whether loki-stack is enabled which brings loki and promtail components(promtail can be separately disabled if needed )
    namespace        = optional(string, null) # the namespace fallbacks to var.namespace if not specified
    create_namespace = optional(bool, true)   # whether create namespace if not exist
    loki = optional(object({
      chart_version    = optional(string, "6.34.0")       # the loki chart version, NOTE: the helm versions >=6.35.0 bring loki-0 pod crash-loops with default configs, makes ure you test things before helm upgrade to newer versions
      release_name     = optional(string, "loki")         # the loki chart release name
      deploymentMode   = optional(string, "SingleBinary") # we have SingleBinary mode by default, and in this mode distributor, ingester, querier, ... and several other components are within single binary loki app
      replicas         = optional(number, 1)              # number of main loki replicas in SingleBinary mode
      auth_enabled     = optional(bool, false)            # should authentication be enabled
      structuredConfig = optional(any, {})                # this provide structured way to pass the loki all configs that available in https://grafana.com/docs/loki/latest/configure/ , for additional field support here code change may be needed or one can use extra_configs option
      commonConfig = optional(object({                    # for more info check https://grafana.com/docs/loki/latest/configuration/#common_config
        replication_factor = optional(number, 1)          # the number of ingesters to write to and read from.
      }), {})
      resources = optional(object({ # resources of loki in SingleBinary mode
        requests = optional(object({
          cpu    = optional(string, "1000m")
          memory = optional(string, "1000Mi")
        }), {})
        limits = optional(object({
          cpu    = optional(string, "1500m")
          memory = optional(string, "2500Mi")
        }), {})
      }), {})
      serviceAccount = optional(object({ # the service account configs that will be assigned to loki main component
        enable      = optional(bool, true)
        name        = optional(string, "loki")
        annotations = optional(map(string), {})
      }), {})
      monitoring = optional(object({ # monitoring related configs
        serviceMonitor = optional(object({
          enabled = optional(bool, true) # whether service monitor is enabled
        }), {})
      }), {})
      ingress = optional(object({ # allows to have loki service accessible from external
        enabled = optional(bool, false)
        type    = optional(string, "nginx")
        public  = optional(bool, true)
        tls = optional(object({
          enabled       = optional(bool, true)
          cert_provider = optional(string, "letsencrypt-prod")
        }), {})
        annotations = optional(map(string), {})
        hosts       = optional(list(string), ["loki.example.com"])
        path        = optional(string, "/")
        path_type   = optional(string, "Prefix")
      }), {})
      schemaConfig = optional(list(object({           # Configures the chunk index schema and where it is stored. for more info check https://grafana.com/docs/loki/latest/configure/#schema_config
        from         = optional(string, "2025-01-01") # defines starting at which date this storage schema will be applied        from         = optional(string, "2025-01-01")
        object_store = optional(string, "filesystem")
        store        = optional(string, "tsdb")
        schema       = optional(string, "v13")
        index = optional(object({
          prefix = optional(string, "index_")
          period = optional(string, "24h")
        }), {})
      })), [{}])
      limits_config = optional(object({                                   # this allows setting limitations and enabling some features for loki. https://grafana.com/docs/loki/latest/configure/#limits_config
        max_query_length          = optional(string, "7d1h")              # the limit to length of chunk store queries. 0 to disable.
        volume_enabled            = optional(bool, true)                  # enables Loki log-volume index queries what can be used in grafana visualize log volume (LogQL → bytes_over_time)
        allow_structured_metadata = optional(bool, true)                  # allow user to send structured metadata in push payload.
        discover_log_levels       = optional(bool, true)                  # discover and add log levels(detected_level) during ingestion, if not present already.
        deletion_mode             = optional(string, "filter-and-delete") # the Deletion mode, Can be one of 'disabled','filter-only', "filter-and-delete". When set to 'filter-only' or 'filter-and-delete', and if retention_enabled=true in the compactor config, then the log entry deletion API endpoints are available
        retention_period          = optional(string, "360h")              # retention period to apply to stored data, only applies if retention_enabled=true in the compactor config. Must be either 0(disabled) or a multiple of 24h, 360h=15days
      }), {})
      compactor_options = optional(object({ # compactor component options, for retention the compactor must run/configured, in "SingleBinary" mode compactor runs in loki single binary and there is no need for compactor separate component so we need only
        retention_enabled    = optional(bool, true)
        working_directory    = optional(string, "/var/loki/compactor")
        delete_request_store = optional(string, "filesystem")
      }), {})
      persistence = optional(object({ # enable persistent disk and configure
        enabled      = optional(bool, true)
        size         = optional(string, "20Gi")
        storageClass = optional(string, "")
        selector     = optional(string, null)
        annotations  = optional(any, {})
      }), {})
      storage = optional(any, { # the storage where loki will place its data, Loki requires a bucket for chunks and the ruler
        type = "filesystem",
        filesystem = {
          chunks_directory    = "/var/loki/chunks"
          rules_directory     = "/var/loki/rules"
          admin_api_directory = "/var/loki/admin"
        }
        bucketNames = {
          chunks = "unused-for-filesystem"
          ruler  = "unused-for-filesystem"
          admin  = "unused-for-filesystem"
        }
      })

      # loki stack other components configs(in SingleBinary mode most of them as separate component are disabled)
      chunksCache = optional(object({            # memcached based cache service which being used for chunks caching and improves loki performance when querying data
        enabled         = optional(bool, true)   # whether enabled, we have this enabled by default, but can be disabled manually
        allocatedMemory = optional(number, 8192) # the memory in MBs we attach to this component, the pods requested memory being calculated based on expression round(allocatedMemory * 1.2)
      }), {})
      resultsCache = optional(object({           # memcached based cache service which being used for chunks caching and improves loki performance when querying data
        enabled         = optional(bool, true)   # whether enabled, we have this enabled by default, but can be disabled manually
        allocatedMemory = optional(number, 1024) # the memory in MBs we attach to this component, the pods requested memory being calculated based on expression round(allocatedMemory * 1.2)
      }), {})
      test           = optional(any, { enabled = false })               # helm tests configs
      lokiCanary     = optional(any, { enabled = false })               # the Loki canary pushes logs to and queries from this loki installation to test that it's working correctly
      ruler          = optional(any, { enabled = false, replicas = 0 }) # the internal loki alerting module, which we do not need as we are going to use grafana alerting mechanism
      compactor      = optional(any, { replicas = 0 })                  # compactor component, in SingleBinary mode this included in loki
      read           = optional(any, { replicas = 0 })                  # read component, in SingleBinary mode this included in loki
      write          = optional(any, { replicas = 0 })                  # write component, in SingleBinary mode this included in loki
      backend        = optional(any, { replicas = 0 })                  # backend component, in SingleBinary mode this included in loki
      ingester       = optional(any, { replicas = 0 })                  # ingester component, in SingleBinary mode this included in loki
      querier        = optional(any, { replicas = 0 })                  # querier component, in SingleBinary mode this included in loki
      queryFrontend  = optional(any, { replicas = 0 })                  # queryFrontend component, in SingleBinary mode this included in loki
      queryScheduler = optional(any, { replicas = 0 })                  # queryScheduler component, in SingleBinary mode this included in loki
      distributor    = optional(any, { replicas = 0 })                  # distributor component, in SingleBinary mode this included in loki
      indexGateway   = optional(any, { replicas = 0 })                  # indexGateway component, in SingleBinary mode this included in loki
      bloomBuilder   = optional(any, { replicas = 0 })                  # bloomBuilder component, in SingleBinary mode this included in loki
      bloomPlanner   = optional(any, { replicas = 0 })                  # bloomPlanner component, in SingleBinary mode this included in loki
      bloomGateway   = optional(any, { replicas = 0 })                  # bloomGateway component, in SingleBinary mode this included in loki

      extra_configs = optional(any, {}) # allows to pass extra/custom configs to loki helm chart, this configs will deep-merged with all generated internal configs and can override the default set ones. All available options can be found in for the specified chart version here: https://artifacthub.io/packages/helm/grafana/loki?modal=values
    }), {})
    # TODO: the promtail deprecated, consider to have this replaced with for example fluent/fluent-bit
    promtail = optional(object({
      enabled               = optional(bool, true)
      chart_version         = optional(string, "6.17.1")
      log_level             = optional(string, "info")
      server_port           = optional(string, "3101")
      clients               = optional(list(string), [])
      log_format            = optional(string, "logfmt")
      extra_scrape_configs  = optional(list(any), [])
      extra_label_configs   = optional(list(map(string)), [])
      extra_pipeline_stages = optional(any, [])
      ignored_containers    = optional(list(string), [])
      ignored_namespaces    = optional(list(string), [])
      extra_configs         = optional(any, {}) # allows to pass extra/custom configs to promtail helm chart, this configs will deep-merged with all generated internal configs and can override the default set ones. All available options can be found in for the specified chart version here: https://artifacthub.io/packages/helm/grafana/promtail?modal=values
    }), {})
  })
  description = "Values to pass to loki helm chart"
  default     = {}
}

variable "dashboards_json_files" {
  type        = list(string)
  default     = []
  description = "Json definition of dashboard. For quickly provisioning dashboards from files"
}

variable "deploy_grafana_stack_dashboard" {
  type        = bool
  default     = true
  description = "Whether to deploy the grafana stack dashboard"
}
