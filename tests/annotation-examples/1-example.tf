module "this" {
  source = "../.."

  grafana_admin_password = "admin"

  application_dashboard = {
    # Global alert format parameters - these will be applied to ALL alerts
    alerts = {
      enabled = true
      alert_format_params = {
        # Global defaults that apply to all alerts
        owner        = "Platform Team"
        provider     = "AWS EKS"
        account      = "production"
        env          = "prod"
        component    = "kubernetes"
        resource     = "deployment"
        impact       = "Service degradation"
        runbook      = "https://example.com/runbooks/kubernetes-alerts"
        issue_phrase = "Service Issue"
        priority     = "P2"
        threshold    = "80%"
        metric       = "resource-usage"
        summary      = "Automated alert from Grafana monitoring"
      }
    }

    variables = [
      {
        "name" : "namespace",
        "options" : [
          {
            "selected" : true,
            "value" : "production"
          },
          {
            "value" : "staging"
          }
        ]
      }
    ]

    rows : [
      # Example 1: Service with basic alerts (no individual annotations)
      {
        type : "block/service",
        name : "api-gateway",
        namespace : "production",
        alerts : {
          enabled : true
          # No individual annotations - will use defaults
        }
      },

      # Example 2: Service with some individual annotations
      {
        type : "block/service",
        name : "user-service",
        namespace : "production",
        alerts : {
          enabled : true
          replicas_no : {
            annotations : {
              "priority"  = "P1"
              "impact"    = "Service completely down"
              "threshold" = "0"
              "metric"    = "replicas"
              "summary"   = "User service has no running replicas"
            }
          }
        }
      },

      # Example 3: Service with mixed annotations (some individual, some defaults)
      {
        type : "block/service",
        name : "payment-service",
        namespace : "production",
        alerts : {
          enabled : true
          cpu : {
            annotations : {
              "priority"  = "P1"
              "threshold" = "90%"
              "impact"    = "API performance degraded"
              "summary"   = "Payment service CPU usage high"
            }
          }
          memory : {
            annotations : {
              "threshold" = "85%"
              "summary"   = "Payment service memory usage high"
            }
          }
        }
      }
    ]
  }

  # Separate alerts block for custom alert rules with message templating
  alerts = {
    # Enable message templating for rich notifications
    enable_message_template = true

    # Global alert format parameters for custom rules
    alert_format_params = {
      owner        = "Platform Team"
      provider     = "AWS EKS"
      account      = "production"
      env          = "prod"
      component    = "infrastructure"
      resource     = "cluster"
      impact       = "Infrastructure issue"
      runbook      = "https://example.com/runbooks/infrastructure-alerts"
      issue_phrase = "Infrastructure Alert"
      priority     = "P1"
      threshold    = "95%"
      metric       = "cluster-metrics"
      summary      = "Infrastructure monitoring alert"
    }

    contact_points = {
      slack = [
        {
          name        = "slack"
          webhook_url = "https://hooks.slack.com/services/xxxx/yyyyyy/zzzzzzzz" # secret value
        }
      ]

    }

    notifications = {
      contact_point   = "slack" # default contact point
      group_interval  = "1m"    # for testing we set this low values, in real setup remove this line to use default
      repeat_interval = "1m"    # for testing we set this low values, in real setup remove this line to use default

      ## to sent all alerts to slack and only P1 priority alerts to opsgenie
      # policies = [
      #   {
      #     contact_point = "opsgenie"
      #     matchers      = [{ label = "priority", match = "=", value = "P1" }]
      #   },
      #   {
      #     contact_point = "slack"
      #   }
      # ]
    }

    # Custom alert rules with different annotation strategies
    rules = [
      # Rule 1: Basic alert with global alert_format_params
      {
        "datasource" : "prometheus",
        "equation" : "gt",
        "expr" : "avg(rate(nginx_ingress_controller_request_duration_seconds_sum[5m])) / avg(rate(nginx_ingress_controller_request_duration_seconds_count[5m]))",
        "function" : "mean",
        "name" : "High Latency Alert",
        "labels" : {
          "priority" : "P2",
        },
        "threshold" : 0.5,
        "no_data_state" : "OK"
        # No annotations - will use global ones from alert_format_params
      },

      # Rule 2: Alert with some individual annotations
      {
        "datasource" : "prometheus",
        "equation" : "gt",
        "expr" : "avg(rate(container_cpu_usage_seconds_total[5m]))",
        "function" : "mean",
        "name" : "High CPU Usage",
        "labels" : {
          "priority" : "P1",
        },
        "threshold" : 0.8,
        "annotations" : {
          "priority"  = "P1"
          "impact"    = "Application performance degraded"
          "threshold" = "80%"
          "metric"    = "cpu-usage"
          "summary"   = "High CPU usage detected across cluster"
          "component" = "kubernetes-pods"
          "runbook"   = "https://example.com/runbooks/cpu-alerts"
          # owner, provider, account, env, resource will use global values from alert_format_params
        },
        "no_data_state" : "OK"
      },

      # Rule 3: Mixed approach - some individual, some global
      {
        "datasource" : "prometheus",
        "equation" : "gt",
        "expr" : "avg(rate(container_memory_usage_bytes[5m])) / avg(container_spec_memory_limit_bytes)",
        "function" : "mean",
        "name" : "High Memory Usage",
        "labels" : {
          "priority" : "P2",
        },
        "threshold" : 0.9,
        "annotations" : {
          "impact"    = "Memory pressure on containers"
          "threshold" = "90%"
          "metric"    = "memory-usage"
          "summary"   = "High memory usage detected"
          # All other annotations will use global values from alert_format_params
        },
        "no_data_state" : "OK"
      }
    ]
  }

  # for this test/example we disable all other components
  grafana = {
    resources = {
      request = {
        cpu = "1"
        mem = "1Gi"
      }
    }
    ingress = {
      type        = "alb"
      tls_enabled = true
      public      = true
      hosts       = ["grafana.example.com"]
      annotations = {
        "alb.ingress.kubernetes.io/certificate-arn" = "arn:aws:acm:us-east-1:123456789012:certificate/example-cert"
        "alb.ingress.kubernetes.io/group.name"      = "grafana-ingress"
      }
    }
    trace_log_mapping = {
      enabled = true
    }
  }

  # Disable other components for this example
  tempo = {
    enabled = false
  }

  loki = {
    enabled = false
  }

  prometheus = {
    enabled = true
  }
}
