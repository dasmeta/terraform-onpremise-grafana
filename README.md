# terraform-onpremise-grafana
https://registry.terraform.io/modules/dasmeta/grafana/onpremise/latest

This module is created to manage any cloud and OnPremise Grafana stack with Terraform.
At this moment we support managing
- Grafana stack
  - grafana
  - prometheus
  - loki(with promtail collector)
  - tempo
- Grafana Dashboard with `dashboard` submodule
- Grafana Alerts with `alerts` submodule
- Grafana Contact Points with `contact-points` submodule
- Grafana Notification Policies with `notifications` submodule

More parts are coming soon.

Starting from version v1.24 All AWS related configuration was removed, making the stack independent from AWS(or any cloud provider). An AWS compatible version will be deployed in a new repository.

## Known issues
Grafana provider sometimes has issues with endpoints behind WAFs: https://github.com/grafana/terraform-provider-grafana/issues/1851


## example for dashboard
```hcl
module "grafana_monitoring" {
  source  = "dasmeta/grafana/onpremise"
  version = "1.7.0"

  name = "Test-dashboard"

  application_dashboard = {
    rows : [
      { type : "block/sla" },
      { type : "block/ingress" },
      { type : "block/service", name : "service-name-1", host : "example.com" },
      { type : "block/service", name : "service-name-2" },
      { type : "block/service", name : "service-name-3" }
    ]
    data_source = {
      uid : "00000"
    }
    variables = [
      {
        "name" : "namespace",
        "options" : [
          {
            "selected" : true,
            "value" : "prod"
          },
          {
            "value" : "stage"
          },
          {
            "value" : "dev"
          }
        ],
      }
    ]
  }
}
```

## Example for Alerts
```
module "grafana_alerts" {
  source  = "dasmeta/grafana/onpremise//modules/alerts"
  version = "1.7.0"

  alerts = {
    rules = [
      {
        name        = "App_1 has 0 available replicas"
        folder_name = "Replica Count"
        datasource  = "prometheus"
        metric_name = "kube_deployment_status_replicas_available"
        filters = {
          deployment = "app-1-microservice"
        }
        function  = "last"
        equation = "lt"
        threshold = 1
      },
      {
        name        = "Nginx Expressions"
        folder_name = "Nginx Expressions Group"
        datasource  = "prometheus"
        expr        = "sum(rate(nginx_ingress_controller_requests{status=~'5..'}[1m])) by (ingress,cluster) / sum(rate(nginx_ingress_controller_requests[1m]))by (ingress) * 100 > 5"
        function    = "mean"
        equation    = "gt"
        threshold   = 2
      },
    ]
    contact_points = {
      opsgenie = [
        {
          name       = "opsgenie"
          api_key    = "xxxxxxxxxxxxxxxx"
          auto_close = true
        }
      ]
      slack = [
        {
          name        = "slack"
          webhook_url = "https://hooks.slack.com/services/xxxxxxxxxxxxxxxx"
        }
      ]
    }
    notifications = {
      contact_point : "slack"
      "policies" : [
        {
          contact_point : "opsgenie"
          matchers : [{ label : "priority", match : "=", value : "P1" }]
        },
        {
          "contact_point" : "slack"
        }
      ]
    }
  }
}
```

## Usage
Check `./tests`, `modules/alert-rules/tests`, `modules/alert-contact-points/tests` and `modules/alert-notifications/tests` folders to see more examples.

## release important notes
- 1.21.0 => 1.22.0
  - we have sla(nginx)/ingress(nginx)/service block alerts integration so that alerts for this dashboard blocks will be created(the service block need to have namespace set), please check `/tests/dashboard-widget-alerts-enabled` example for full complete possible options
  - all underlying components got upgraded and some have incompatible changes
  - loki-stack have been removed and replaced with separate loki and promtail helm charts, to not have issue before applying the new version remove "loki-stack" chart via command:
  ```terraform
  helm uninstall loki-stack
  ```
  - there is an issue related to dependencies, when we have alerts created and we change grafana/prometheus some params we get `'The "count" value depends on resource attributes that cannot be determined until apply'` error. As workaround just disable alerts and apply things and then red-enable apply again

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_grafana"></a> [grafana](#requirement\_grafana) | >= 3.0.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | >= 2.4.1, < 3.0.0 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_alerts"></a> [alerts](#module\_alerts) | ./modules/alerts | n/a |
| <a name="module_application_dashboard"></a> [application\_dashboard](#module\_application\_dashboard) | ./modules/dashboard/ | n/a |
| <a name="module_application_dashboard_json"></a> [application\_dashboard\_json](#module\_application\_dashboard\_json) | ./modules/dashboard-json | n/a |
| <a name="module_grafana"></a> [grafana](#module\_grafana) | ./modules/grafana | n/a |
| <a name="module_loki"></a> [loki](#module\_loki) | ./modules/loki | n/a |
| <a name="module_prometheus"></a> [prometheus](#module\_prometheus) | ./modules/prometheus | n/a |
| <a name="module_tempo"></a> [tempo](#module\_tempo) | ./modules/tempo | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_alerts"></a> [alerts](#input\_alerts) | Alerting configurations, NOTE: we have also option to create alert rules attached to dashboard widget blocks | <pre>object({<br/>    alert_interval_seconds  = optional(number, 10)       # The interval, in seconds, at which all rules in the group are evaluated. If a group contains many rules, the rules are evaluated sequentially<br/>    disable_provenance      = optional(bool, true)       # Allow modifying resources from other sources than Terraform or the Grafana API<br/>    create_folder           = optional(bool, false)      # whether to create folder to place app dashboard and alerts there, if folder with provided name exist already no need to create it again<br/>    folder_name             = optional(string, null)     # The folder name for dashboard, if not set it defaults to var.application_dashboard.folder_name<br/>    group                   = optional(string, "custom") # The alerts general group name<br/>    enable_message_template = optional(bool, true)       # Whether to enable the message template for the alerts<br/>    # Predefined annotations structure for all alerts<br/>    # These annotations will be applied to all alerts and can be overridden by rule-specific annotations<br/>    # Values provided here will also be available in notification templates<br/>    annotations = optional(object({<br/>      component    = optional(string, "") # Component or service name (e.g., "kubernetes", "database", "api")<br/>      owner        = optional(string, "") # Team or person responsible for the alert (e.g., "Platform Team", "DevOps")<br/>      issue_phrase = optional(string, "") # Brief description of the issue type (e.g., "Service Issue", "Infrastructure Alert")<br/>      impact       = optional(string, "") # Description of the impact (e.g., "Service degradation", "Complete outage")<br/>      runbook      = optional(string, "") # URL to runbook or documentation for resolving the issue<br/>      provider     = optional(string, "") # Cloud provider or platform (e.g., "AWS EKS", "GCP", "Azure")<br/>      account      = optional(string, "") # Account or environment identifier (e.g., "production", "staging")<br/>      threshold    = optional(string, "") # Threshold value that triggered the alert (e.g., "80%", "100ms")<br/>      metric       = optional(string, "") # Metric name or type being monitored (e.g., "cpu-usage", "response-time")<br/>    }), {})<br/><br/>    # Predefined labels structure for all alerts<br/>    labels = optional(object({<br/>      priority = optional(string, "P2")<br/>      severity = optional(string, "warning")<br/>      env      = optional(string, "")<br/>    }), {})<br/>    rules = optional(<br/>      list(object({                                 # Describes custom alert rules<br/>        name           = string                     # The name of the alert rule<br/>        no_data_state  = optional(string, "NoData") # Describes what state to enter when the rule's query returns No Data<br/>        exec_err_state = optional(string, "Error")  # Describes what state to enter when the rule's query is invalid and the rule cannot be executed<br/><br/>        labels               = optional(map(any), {})        # Labels help to define matchers in notification policy to control where to send each alert. Can be any key-value pairs<br/>        annotations          = optional(map(string), {})     # Annotations to set to the alert rule. Annotations will be used to customize the alert message in notifications template. Can be any key-value pairs<br/>        group                = optional(string, "custom")    # Grafana alert group name in which the rule will be created/grouped<br/>        datasource           = string                        # Name of the datasource used for the alert<br/>        expr                 = optional(string, null)        # Full expression for the alert<br/>        metric_name          = optional(string, "")          # Prometheus metric name which queries the data for the alert<br/>        metric_function      = optional(string, "")          # Prometheus function used with metric for queries, like rate, sum etc.<br/>        metric_interval      = optional(string, "")          # The time interval with using functions like rate<br/>        settings_mode        = optional(string, "replaceNN") # The mode used in B block, possible values are Strict, replaceNN, dropNN<br/>        settings_replaceWith = optional(number, 0)           # The value by which NaN results of the query will be replaced<br/>        filters              = optional(any, {})             # Filters object to identify each service for alerting<br/>        function             = optional(string, "mean")      # One of Reduce functions which will be used in B block for alerting<br/>        equation             = string                        # The equation in the math expression which compares B blocks value with a number and generates an alert if needed. Possible values: gt, lt, gte, lte, e<br/>        threshold            = number                        # The value against which B blocks are compared in the math expression<br/>    })), [])<br/>    contact_points = optional(object({<br/>      slack = optional(list(object({                                                         # Slack contact points list<br/>        name                    = string                                                     # The name of the contact point<br/>        endpoint_url            = optional(string, "https://slack.com/api/chat.postMessage") # Use this to override the Slack API endpoint URL to send requests to<br/>        icon_emoji              = optional(string, "")                                       # The name of a Slack workspace emoji to use as the bot icon<br/>        icon_url                = optional(string, "")                                       # A URL of an image to use as the bot icon<br/>        recipient               = optional(string, null)                                     # Channel, private group, or IM channel (can be an encoded ID or a name) to send messages to<br/>        text                    = optional(string, "")                                       # Templated content of the message<br/>        title                   = optional(string, "")                                       # Templated title of the message<br/>        token                   = optional(string, "")                                       # A Slack API token,for sending messages directly without the webhook method<br/>        webhook_url             = optional(string, "")                                       # A Slack webhook URL,for sending messages via the webhook method<br/>        username                = optional(string, "")                                       # Username for the bot to use<br/>        disable_resolve_message = optional(bool, false)                                      # Whether to disable sending resolve messages<br/>      })), [])<br/>      opsgenie = optional(list(object({                                                  # OpsGenie contact points list<br/>        name                    = string                                                 # The name of the contact point<br/>        api_key                 = string                                                 # The OpsGenie API key to use<br/>        auto_close              = optional(bool, false)                                  # Whether to auto-close alerts in OpsGenie when they resolve in the Alert manager<br/>        message                 = optional(string, "")                                   # The templated content of the message<br/>        api_url                 = optional(string, "https://api.opsgenie.com/v2/alerts") # Allows customization of the OpsGenie API URL<br/>        disable_resolve_message = optional(bool, false)                                  # Whether to disable sending resolve messages<br/>      })), [])<br/>      teams = optional(list(object({                    # Teams contact points list<br/>        name                    = string                # The name of the contact point<br/>        url                     = string                # The MS Teams Webhook URL to use<br/>        message                 = optional(string, "")  # The templated content of the message<br/>        disable_resolve_message = optional(bool, false) # Whether to disable sending resolve messages<br/>        section_title           = optional(string, "")  # The templated subtitle for each message section.<br/>        title                   = optional(string, "")  # The templated title of the message<br/>      })), [])<br/>      webhook = optional(list(object({                     # Contact points that send notifications to an arbitrary webhook, using the Prometheus webhook format<br/>        name                      = string                 # The name of the contact point<br/>        url                       = string                 # The URL to send webhook requests to<br/>        authorization_credentials = optional(string, null) # Allows a custom authorization scheme - attaches an auth header with this value. Do not use in conjunction with basic auth parameters<br/>        authorization_scheme      = optional(string, null) # Allows a custom authorization scheme - attaches an auth header with this name. Do not use in conjunction with basic auth parameters<br/>        basic_auth_password       = optional(string, null) # The password component of the basic auth credentials to use<br/>        basic_auth_user           = optional(string, null) # The username component of the basic auth credentials to use<br/>        disable_resolve_message   = optional(bool, false)  # Whether to disable sending resolve messages. Defaults to<br/>        settings                  = optional(any, null)    # Additional custom properties to attach to the notifier<br/>      })), [])<br/>    }), null)<br/>    notifications = optional(object({<br/>      contact_point   = optional(string, "Slack")       # The default contact point to route all unmatched notifications to<br/>      group_by        = optional(list(string), ["..."]) # A list of alert labels to group alerts into notifications by<br/>      group_interval  = optional(string, "5m")          # Minimum time interval between two notifications for the same group<br/>      repeat_interval = optional(string, "4h")          # Minimum time interval for re-sending a notification if an alert is still firing<br/><br/>      mute_timing = optional(object({                  # Mute timing config, which will be applied on all policies<br/>        name = optional(string, "Default mute timing") # the name of mute timing<br/>        intervals = optional(list(object({             # the mute timing interval configs<br/>          weekdays      = optional(string, null)<br/>          days_of_month = optional(string, null)<br/>          months        = optional(string, null)<br/>          years         = optional(string, null)<br/>          location      = optional(string, null)<br/>          times = optional(object({<br/>            start = optional(string, "00:00")<br/>            end   = optional(string, "24:59")<br/>          }), null)<br/>        })), [])<br/>      }), null)<br/><br/>      policies = optional(list(object({<br/>        contact_point = optional(string, null) # The contact point to route notifications that match this rule to<br/>        continue      = optional(bool, true)   # Whether to continue matching subsequent rules if an alert matches the current rule. Otherwise, the rule will be 'consumed' by the first policy to match it<br/>        group_by      = optional(list(string), ["..."])<br/><br/>        matchers = optional(list(object({<br/>          label = optional(string, "priority") # The name of the label to match against<br/>          match = optional(string, "=")        # The operator to apply when matching values of the given label. Allowed operators are = for equality, != for negated equality, =~ for regex equality, and !~ for negated regex equality<br/>          value = optional(string, "P1")       # The label value to match against<br/>        })), [])<br/>        policies = optional(list(object({ # sub-policies(there is also possibility to implement also ability for sub.sub.sub-policies, but for not seems existing configs are enough)<br/>          contact_point = optional(string, null)<br/>          continue      = optional(bool, true)<br/>          group_by      = optional(list(string), ["..."])<br/>          mute_timings  = optional(list(string), [])<br/><br/>          matchers = optional(list(object({<br/>            label = optional(string, "priority")<br/>            match = optional(string, "=")<br/>            value = optional(string, "P1")<br/>          })), [])<br/>        })), [])<br/>      })), [])<br/>    }), null)<br/>  })</pre> | `{}` | no |
| <a name="input_application_dashboard"></a> [application\_dashboard](#input\_application\_dashboard) | Dashboard for monitoring applications | <pre>object({<br/>    folder_name = optional(string, "application-dashboard") # the folder name for dashboard<br/>    rows        = optional(any, [])<br/>    data_source = optional(object({<br/>      uid  = optional(string, "prometheus")<br/>      type = optional(string, "prometheus")<br/>    }), {})<br/>    variables = optional(list(object({ # Allows to define variables to be used in dashboard<br/>      name        = string<br/>      type        = optional(string, "custom")<br/>      hide        = optional(number, 0)<br/>      includeAll  = optional(bool, false)<br/>      multi       = optional(bool, false)<br/>      query       = optional(string, "")<br/>      queryValue  = optional(string, "")<br/>      skipUrlSync = optional(bool, false)<br/>      options = optional(list(object({<br/>        selected = optional(bool, false)<br/>        value    = string<br/>        text     = optional(string, null)<br/>      })), [])<br/>    })), [])<br/>    alerts = optional(any, { enabled = true }) # Allows to configure globally dashboard block/(sla|ingress|service) blocks/widgets related alerts<br/>  })</pre> | <pre>{<br/>  "data_source": null,<br/>  "rows": [],<br/>  "variables": []<br/>}</pre> | no |
| <a name="input_dashboards_json_files"></a> [dashboards\_json\_files](#input\_dashboards\_json\_files) | Json definition of dashboard. For quickly provisioning the dashboards | `list(string)` | `[]` | no |
| <a name="input_grafana"></a> [grafana](#input\_grafana) | Values to construct the values file for Grafana Helm chart | <pre>object({<br/>    enabled       = optional(bool, true)<br/>    chart_version = optional(string, "9.2.9")<br/>    resources = optional(object({<br/>      request = optional(object({<br/>        cpu = optional(string, "1")<br/>        mem = optional(string, "2Gi")<br/>      }), {})<br/>      limit = optional(object({<br/>        cpu = optional(string, "2")<br/>        mem = optional(string, "3Gi")<br/>      }), {})<br/>    }), {})<br/>    database = optional(object({           # configure external(or in helm created) database base storing/persisting grafana data<br/>      enabled       = optional(bool, true) # whether database based persistence is enabled<br/>      create        = optional(bool, true) # whether to create mysql databases or use already existing database<br/>      name          = optional(string, "grafana")<br/>      type          = optional(string, "mysql") # when we set external database we can set any sql compatible one like postgresql or ms sql, but when we create database it supports only mysql and changing this field do not affect<br/>      host          = optional(string, null)    # it will set right host for grafana mysql in case create=true<br/>      user          = optional(string, "grafana")<br/>      password      = optional(string, null)     # if not set it will use var.grafana_admin_password<br/>      root_password = optional(string, null)     # if not set it will use var.grafana_admin_password<br/>      persistence = optional(object({            # allows to configure created(when database.create=true) mysql databases storage/persistence configs<br/>        enabled       = optional(bool, true)     # whether to have created in k8s mysql database with persistence<br/>        size          = optional(string, "20Gi") # the size of primary persistent volume of mysql when creating it<br/>        storage_class = optional(string, "")     # default storage class for the mysql database<br/>      }), {})<br/>      # the size of primary persistent volume of mysql when creating it<br/>      extra_flags = optional(string, "--skip-log-bin") # allows to set extra flags(whitespace separated) on grafana mysql primary instance, we have by default skip-log-bin flag set to disable bin-logs which overload mysql disc and/but we do not use multi replica mysql here<br/>    }), {})<br/>    persistence = optional(object({ # configure pvc base storing/persisting grafana data(it uses sqlite DB in this mode), NOTE: we use mysql database for data storage by default and no need to enable persistence if DB is set, so that we have persistence disable here by default<br/>      enabled       = optional(bool, false)<br/>      type          = optional(string, "pvc")<br/>      size          = optional(string, "20Gi")<br/>      storage_class = optional(string, "")<br/>    }), {})<br/>    ingress = optional(object({<br/>      annotations = optional(map(string), {})<br/>      hosts       = optional(list(string), ["grafana.example.com"])<br/>      path        = optional(string, "/")<br/>      path_type   = optional(string, "Prefix")<br/>      type        = optional(string, "alb")<br/>      public      = optional(bool, true)<br/>      tls_enabled = optional(bool, true)<br/>    }))<br/>    service_account = optional(object({<br/>      name        = optional(string, "grafana")<br/>      enable      = optional(bool, true)<br/>      annotations = optional(map(string), {})<br/>    }), {})<br/>    redundancy = optional(object({<br/>      enabled      = optional(bool, false)<br/>      max_replicas = optional(number, 4)<br/>      min_replicas = optional(number, 1)<br/>    }), {})<br/><br/>    datasources = optional(list(map(any))) # a list of grafana datasource configurations. Based on the type of the datasource the module will fill in the missing configuration for some supported datasources. Mandatory are name and type fields<br/>    trace_log_mapping = optional(object({<br/>      enabled       = optional(bool, false)<br/>      trace_pattern = optional(string, "trace_id=(\\w+)")<br/>    }), {})<br/><br/>    replicas = optional(number, 1)<br/>  })</pre> | `{}` | no |
| <a name="input_grafana_admin_password"></a> [grafana\_admin\_password](#input\_grafana\_admin\_password) | grafana admin user password | `string` | `""` | no |
| <a name="input_loki"></a> [loki](#input\_loki) | Values to pass to loki helm chart | <pre>object({<br/>    enabled       = optional(bool, false)<br/>    chart_version = optional(string, "6.30.1")<br/>    loki = optional(object({<br/>      url            = optional(string, "")<br/>      volume_enabled = optional(bool, true)<br/>      service_account = optional(object({<br/>        enable      = optional(bool, true)<br/>        name        = optional(string, "loki")<br/>        annotations = optional(map(string), {})<br/>      }), {})<br/>      persistence = optional(object({<br/>        enabled       = optional(bool, true)<br/>        size          = optional(string, "20Gi")<br/>        storage_class = optional(string, "")<br/>        access_mode   = optional(string, "ReadWriteOnce")<br/>      }), {})<br/>      limits_config = optional(map(string), {}) # This allows setting limitations and enabling some features for loki. https://grafana.com/docs/loki/latest/configure/#limits_config<br/>      schema_configs = optional(list(object({<br/>        from         = optional(string, "2025-01-01") # defines starting at which date this storage schema will be applied<br/>        object_store = optional(string, "filesystem")<br/>        store        = optional(string, "tsdb")<br/>        schema       = optional(string, "v13")<br/>        index = optional(object({<br/>          prefix = optional(string, "index_")<br/>          period = optional(string, "24h")<br/>        }), {})<br/>      })), [{}])<br/>      storage = optional(any, {<br/>        type = "filesystem",<br/>        filesystem = {<br/>          chunks_directory    = "/var/loki/chunks"<br/>          rules_directory     = "/var/loki/rules"<br/>          admin_api_directory = "/var/loki/admin"<br/>        }<br/>        bucketNames = {<br/>          chunks = "unused-for-filesystem"<br/>          ruler  = "unused-for-filesystem"<br/>          admin  = "unused-for-filesystem"<br/>        }<br/>      })<br/>      ingress = optional(object({<br/>        enabled     = optional(bool, false)<br/>        type        = optional(string, "nginx")<br/>        public      = optional(bool, true)<br/>        tls_enabled = optional(bool, true)<br/><br/>        annotations = optional(map(string), {})<br/>        hosts       = optional(list(string), ["loki.exampleeee.com"])<br/>        path        = optional(string, "/")<br/>        path_type   = optional(string, "Prefix")<br/>      }), {})<br/>      replicas         = optional(number, 1)<br/>      retention_period = optional(string, "168h")<br/>      resources = optional(object({<br/>        request = optional(object({<br/>          cpu = optional(string, "200m")<br/>          mem = optional(string, "250Mi")<br/>        }), {})<br/>        limit = optional(object({<br/>          cpu = optional(string, "400m")<br/>          mem = optional(string, "500Mi")<br/>        }), {})<br/>      }), {})<br/>    }), {})<br/>    promtail = optional(object({<br/>      enabled               = optional(bool, true)<br/>      log_level             = optional(string, "info")<br/>      server_port           = optional(string, "3101")<br/>      clients               = optional(list(string), [])<br/>      log_format            = optional(string, "logfmt")<br/>      extra_scrape_configs  = optional(list(any), [])<br/>      extra_label_configs   = optional(list(map(string)), [])<br/>      extra_pipeline_stages = optional(any, [])<br/>      ignored_containers    = optional(list(string), [])<br/>      ignored_namespaces    = optional(list(string), [])<br/>    }), {})<br/>  })</pre> | `{}` | no |
| <a name="input_name"></a> [name](#input\_name) | Dashboard name | `string` | n/a | yes |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | n/a | `string` | `"monitoring"` | no |
| <a name="input_prometheus"></a> [prometheus](#input\_prometheus) | values to be used as prometheus's chart values | <pre>object({<br/>    enabled        = optional(bool, true)<br/>    chart_version  = optional(string, "75.8.0")<br/>    retention_days = optional(string, "15d")<br/>    storage_class  = optional(string, "")<br/>    storage_size   = optional(string, "100Gi")<br/>    access_modes   = optional(list(string), ["ReadWriteOnce"])<br/>    resources = optional(object({<br/>      request = optional(object({<br/>        cpu = optional(string, "500m")<br/>        mem = optional(string, "500Mi")<br/>      }), {})<br/>      limit = optional(object({<br/>        cpu = optional(string, "1")<br/>        mem = optional(string, "1Gi")<br/>      }), {})<br/>    }), {})<br/>    replicas            = optional(number, 2)<br/>    enable_alertmanager = optional(bool, true)<br/>    ingress = optional(object({<br/>      enabled     = optional(bool, false)<br/>      type        = optional(string, "nginx")<br/>      public      = optional(bool, true)<br/>      tls_enabled = optional(bool, true)<br/><br/>      annotations = optional(map(string), {})<br/>      hosts       = optional(list(string), ["prometheus.example.com"])<br/>      path        = optional(list(string), ["/"])<br/>      path_type   = optional(string, "Prefix")<br/>    }), {})<br/>  })</pre> | `{}` | no |
| <a name="input_tempo"></a> [tempo](#input\_tempo) | confgis for tempo deployment | <pre>object({<br/>    enabled       = optional(bool, false)<br/>    chart_version = optional(string, "1.20.0")<br/>    service_account = optional(object({<br/>      name        = optional(string, "tempo")<br/>      annotations = optional(map(string), {})<br/>    }), {})<br/>    storage = optional(object({<br/>      backend = optional(string, "local")<br/>      backend_configuration = optional(map(any), {<br/>        local = { path = "/var/tempo/traces" },<br/>        wal   = { path = "/var/tempo/wal" }<br/>      })<br/>    }), {})<br/>    enable_service_monitor = optional(bool, true)<br/>    oidc_provider_arn      = optional(string, "")<br/><br/>    metrics_generator = optional(object({<br/>      enabled    = optional(bool, true)<br/>      remote_url = optional(string, "http://prometheus-kube-prometheus-prometheus.monitoring.svc.cluster.local:9090/api/v1/write")<br/>    }))<br/><br/>    persistence = optional(object({<br/>      enabled       = optional(bool, true)<br/>      size          = optional(string, "20Gi")<br/>      storage_class = optional(string, "")<br/>    }), {})<br/>  })</pre> | `{}` | no |

## Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
