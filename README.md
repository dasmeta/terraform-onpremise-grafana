# terraform-onpremise-grafana
https://registry.terraform.io/modules/dasmeta/grafana/onpremise/latest

This module is created to manage OnPremise Grafana stack with Terraform.
At this moment we support managing
- Grafana Dashboard with `dashboard` submodule
- Grafana Alerts with `alerts` submodule
- Grafana Contact Points with `contact-points` submodule
- Grafana Notification Policies with `notifications` submodule

More parts are coming soon.

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

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_grafana"></a> [grafana](#requirement\_grafana) | >= 3.0.0 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_alerts"></a> [alerts](#module\_alerts) | ./modules/alerts | n/a |
| <a name="module_application_dashboard"></a> [application\_dashboard](#module\_application\_dashboard) | ./modules/dashboard/ | n/a |
| <a name="module_grafana"></a> [grafana](#module\_grafana) | ./modules/grafana | n/a |
| <a name="module_prometheus"></a> [prometheus](#module\_prometheus) | ./modules/prometheus | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_alerts"></a> [alerts](#input\_alerts) | n/a | <pre>object({<br/>    alert_interval_seconds = optional(number, 10) # The interval, in seconds, at which all rules in the group are evaluated. If a group contains many rules, the rules are evaluated sequentially<br/>    disable_provenance     = optional(bool, true) # Allow modifying resources from other sources than Terraform or the Grafana API<br/>    rules = optional(                             # Describes alert folders, groups and rules<br/>      list(object({<br/>        name                 = string                                    # The name of the alert rule<br/>        no_data_state        = optional(string, "NoData")                # Describes what state to enter when the rule's query returns No Data<br/>        exec_err_state       = optional(string, "Error")                 # Describes what state to enter when the rule's query is invalid and the rule cannot be executed<br/>        summary              = optional(string, null)                    # Rule annotation as a summary, if not passed automatically generated based on data<br/>        labels               = optional(map(any), { "priority" : "P1" }) # Labels help to define matchers in notification policy to control where to send each alert<br/>        folder_name          = optional(string, "Main Alerts")           # Grafana folder name in which the rule will be created, the folder name used also as alert group name with suffix " Group"<br/>        datasource           = string                                    # Name of the datasource used for the alert<br/>        expr                 = optional(string, null)                    # Full expression for the alert<br/>        metric_name          = optional(string, "")                      # Prometheus metric name which queries the data for the alert<br/>        metric_function      = optional(string, "")                      # Prometheus function used with metric for queries, like rate, sum etc.<br/>        metric_interval      = optional(string, "")                      # The time interval with using functions like rate<br/>        settings_mode        = optional(string, "replaceNN")             # The mode used in B block, possible values are Strict, replaceNN, dropNN<br/>        settings_replaceWith = optional(number, 0)                       # The value by which NaN results of the query will be replaced<br/>        filters              = optional(any, null)                       # Filters object to identify each service for alerting<br/>        function             = optional(string, "mean")                  # One of Reduce functions which will be used in B block for alerting<br/>        equation             = string                                    # The equation in the math expression which compares B blocks value with a number and generates an alert if needed. Possible values: gt, lt, gte, lte, e<br/>        threshold            = number                                    # The value against which B blocks are compared in the math expression<br/>    })), [])<br/>    contact_points = optional(object({<br/>      slack = optional(list(object({                                                         # Slack contact points list<br/>        name                    = string                                                     # The name of the contact point<br/>        endpoint_url            = optional(string, "https://slack.com/api/chat.postMessage") # Use this to override the Slack API endpoint URL to send requests to<br/>        icon_emoji              = optional(string, "")                                       # The name of a Slack workspace emoji to use as the bot icon<br/>        icon_url                = optional(string, "")                                       # A URL of an image to use as the bot icon<br/>        recipient               = optional(string, null)                                     # Channel, private group, or IM channel (can be an encoded ID or a name) to send messages to<br/>        text                    = optional(string, "")                                       # Templated content of the message<br/>        title                   = optional(string, "")                                       # Templated title of the message<br/>        token                   = optional(string, "")                                       # A Slack API token,for sending messages directly without the webhook method<br/>        webhook_url             = optional(string, "")                                       # A Slack webhook URL,for sending messages via the webhook method<br/>        username                = optional(string, "")                                       # Username for the bot to use<br/>        disable_resolve_message = optional(bool, false)                                      # Whether to disable sending resolve messages<br/>      })), [])<br/>      opsgenie = optional(list(object({                                                  # OpsGenie contact points list<br/>        name                    = string                                                 # The name of the contact point<br/>        api_key                 = string                                                 # The OpsGenie API key to use<br/>        auto_close              = optional(bool, false)                                  # Whether to auto-close alerts in OpsGenie when they resolve in the Alert manager<br/>        message                 = optional(string, "")                                   # The templated content of the message<br/>        api_url                 = optional(string, "https://api.opsgenie.com/v2/alerts") # Allows customization of the OpsGenie API URL<br/>        disable_resolve_message = optional(bool, false)                                  # Whether to disable sending resolve messages<br/>      })), [])<br/>      teams = optional(list(object({                    # Teams contact points list<br/>        name                    = string                # The name of the contact point<br/>        url                     = string                # The MS Teams Webhook URL to use<br/>        message                 = optional(string, "")  # The templated content of the message<br/>        disable_resolve_message = optional(bool, false) # Whether to disable sending resolve messages<br/>        section_title           = optional(string, "")  # The templated subtitle for each message section.<br/>        title                   = optional(string, "")  # The templated title of the message<br/>      })), [])<br/>      webhook = optional(list(object({                     # Contact points that send notifications to an arbitrary webhook, using the Prometheus webhook format<br/>        name                      = string                 # The name of the contact point<br/>        url                       = string                 # The URL to send webhook requests to<br/>        authorization_credentials = optional(string, null) # Allows a custom authorization scheme - attaches an auth header with this value. Do not use in conjunction with basic auth parameters<br/>        authorization_scheme      = optional(string, null) # Allows a custom authorization scheme - attaches an auth header with this name. Do not use in conjunction with basic auth parameters<br/>        basic_auth_password       = optional(string, null) # The password component of the basic auth credentials to use<br/>        basic_auth_user           = optional(string, null) # The username component of the basic auth credentials to use<br/>        disable_resolve_message   = optional(bool, false)  # Whether to disable sending resolve messages. Defaults to<br/>        settings                  = optional(any, null)    # Additional custom properties to attach to the notifier<br/>      })), [])<br/>    }), null)<br/>    notifications = optional(object({<br/>      contact_point   = optional(string, "Slack")       # The default contact point to route all unmatched notifications to<br/>      group_by        = optional(list(string), ["..."]) # A list of alert labels to group alerts into notifications by<br/>      group_interval  = optional(string, "5m")          # Minimum time interval between two notifications for the same group<br/>      repeat_interval = optional(string, "4h")          # Minimum time interval for re-sending a notification if an alert is still firing<br/><br/>      mute_timing = optional(object({                  # Mute timing config, which will be applied on all policies<br/>        name = optional(string, "Default mute timing") # the name of mute timing<br/>        intervals = optional(list(object({             # the mute timing interval configs<br/>          weekdays      = optional(string, null)<br/>          days_of_month = optional(string, null)<br/>          months        = optional(string, null)<br/>          years         = optional(string, null)<br/>          location      = optional(string, null)<br/>          times = optional(object({<br/>            start = optional(string, "00:00")<br/>            end   = optional(string, "24:59")<br/>          }), null)<br/>        })), [])<br/>      }), null)<br/><br/>      policies = optional(list(object({<br/>        contact_point = optional(string, null) # The contact point to route notifications that match this rule to<br/>        continue      = optional(bool, true)   # Whether to continue matching subsequent rules if an alert matches the current rule. Otherwise, the rule will be 'consumed' by the first policy to match it<br/>        group_by      = optional(list(string), ["..."])<br/><br/>        matchers = optional(list(object({<br/>          label = optional(string, "priority") # The name of the label to match against<br/>          match = optional(string, "=")        # The operator to apply when matching values of the given label. Allowed operators are = for equality, != for negated equality, =~ for regex equality, and !~ for negated regex equality<br/>          value = optional(string, "P1")       # The label value to match against<br/>        })), [])<br/>        policies = optional(list(object({ # sub-policies(there is also possibility to implement also ability for sub.sub.sub-policies, but for not seems existing configs are enough)<br/>          contact_point = optional(string, null)<br/>          continue      = optional(bool, true)<br/>          group_by      = optional(list(string), ["..."])<br/>          mute_timings  = optional(list(string), [])<br/><br/>          matchers = optional(list(object({<br/>            label = optional(string, "priority")<br/>            match = optional(string, "=")<br/>            value = optional(string, "P1")<br/>          })), [])<br/>        })), [])<br/>      })), [])<br/>    }), null)<br/>  })</pre> | `{}` | no |
| <a name="input_application_dashboard"></a> [application\_dashboard](#input\_application\_dashboard) | Dashboard for monitoring applications | <pre>object({<br/>    rows = optional(any, [])<br/>    data_source = object({ # global/default datasource, TODO: create datasource inside the module<br/>      uid  = string<br/>      type = optional(string, "prometheus")<br/>    })<br/>    variables = optional(list(object({ # Allows to define variables to be used in dashboard<br/>      name        = string<br/>      type        = optional(string, "custom")<br/>      hide        = optional(number, 0)<br/>      includeAll  = optional(bool, false)<br/>      multi       = optional(bool, false)<br/>      query       = optional(string, "")<br/>      queryValue  = optional(string, "")<br/>      skipUrlSync = optional(bool, false)<br/>      options = optional(list(object({<br/>        selected = optional(bool, false)<br/>        value    = string<br/>        text     = optional(string, null)<br/>      })), [])<br/>    })), [])<br/>  })</pre> | <pre>{<br/>  "data_source": null,<br/>  "rows": [],<br/>  "variables": []<br/>}</pre> | no |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | n/a | `string` | `"eu-central-1"` | no |
| <a name="input_grafana_admin_password"></a> [grafana\_admin\_password](#input\_grafana\_admin\_password) | grafana admin user password | `string` | `""` | no |
| <a name="input_grafana_configs"></a> [grafana\_configs](#input\_grafana\_configs) | Values to construct the values file for Grafana Helm chart | <pre>object({<br/>    enabled = optional(bool, true)<br/>    resources = optional(object({<br/>      request = optional(object({<br/>        cpu = optional(string, "1")<br/>        mem = optional(string, "2Gi")<br/>      }), {})<br/>      limit = optional(object({<br/>        cpu = optional(string, "2")<br/>        mem = optional(string, "3Gi")<br/>      }), {})<br/>    }), {})<br/>    persistence = optional(object({<br/>      enabled = optional(bool, true)<br/>      type    = optional(string, "pvc")<br/>      size    = optional(string, "10Gi")<br/>    }), {})<br/>    ingress_configs = optional(object({<br/>      annotations = optional(map(string),<br/>        {<br/>          "kubernetes.io/ingress.class"                = "alb"<br/>          "alb.ingress.kubernetes.io/scheme"           = "internet-facing"<br/>          "alb.ingress.kubernetes.io/target-type"      = "ip"<br/>          "alb.ingress.kubernetes.io/listen-ports"     = "[{\"HTTP\": 80}]"<br/>          "alb.ingress.kubernetes.io/group.name"       = "monitoring"<br/>          "alb.ingress.kubernetes.io/healthcheck-path" = "/api/health"<br/>        }<br/>      )<br/>      hosts     = optional(list(string), ["grafana.example.com"])<br/>      path      = optional(string, "/")<br/>      path_type = optional(string, "Prefix")<br/>    }))<br/>    prometheus_url = optional(string, "http://prometheus-operated.monitoring.svc.cluster.local:9090")<br/><br/>    replicas  = optional(number, 1)<br/>    image_tag = optional(string, "11.4.2")<br/>  })</pre> | `{}` | no |
| <a name="input_name"></a> [name](#input\_name) | Dashboard name | `string` | n/a | yes |
| <a name="input_prometheus_configs"></a> [prometheus\_configs](#input\_prometheus\_configs) | values to be used as prometheus's chart values | <pre>object({<br/>    enabled        = optional(bool, true)<br/>    retention_days = optional(string, "15d")<br/>    storage_class  = optional(string, "efs-sc-root")<br/>    storage_size   = optional(string, "10Gi")<br/>    resources = optional(object({<br/>      request = optional(object({<br/>        cpu = optional(string, "500m")<br/>        mem = optional(string, "500Mi")<br/>      }), {})<br/>      limit = optional(object({<br/>        cpu = optional(string, "1")<br/>        mem = optional(string, "1Gi")<br/>      }), {})<br/>    }), {})<br/>    enable_alertmanager = optional(bool, true)<br/>  })</pre> | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_data"></a> [data](#output\_data) | n/a |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
