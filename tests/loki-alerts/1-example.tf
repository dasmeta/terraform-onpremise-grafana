module "this" {
  source = "../.."

  deploy_grafana_stack_dashboard = false
  application_dashboard = [
    {
      name        = "Test-dashboard",
      folder_name = "Test-dashboard",
      alerts      = { enabled = false },
      rows : [
        { type : "block/service", name = "worker", show_err_logs = true, loki_datasource_uid = "loki", namespace = "dev", pvc_name = "pvc_name" }
      ]
      data_source = {
        uid = "prometheus"
      }

      variables = [
        {
          "name" : "namespace",
          "options" : [
            {
              "value" : "prod"
            },
            {
              "selected" : true,
              "value" : "dev"
            }
          ],
        }
      ]
    }
  ]

  alerts = {
    rules = [
      {
        datasource  = "prometheus",
        equation    = "gt",
        expr        = "avg(increase(nginx_ingress_controller_request_duration_seconds_sum[3m])) / 10",
        folder_name = "Nginx Alerts",
        function    = "mean",
        name        = "Latency P1",
        labels = {
          priority = "P1",
        },
        threshold = 3,
        summary   = "This is the summary1",

        # we override no-data/exec-error state for this example/test only, it is supposed this values will not be set here so they get their default ones
        no_data_state  = "OK",
        exec_err_state = "OK"
        # "exec_err_state" : "Alerting" # uncomment to trigger new alert
      },
      {
        name           = "Too many errors in logs"
        datasource     = "Loki"
        type           = "log"
        expr           = "count_over_time({app=\"frontend\"} |= \"ERROR\" [5m])"
        threshold      = 100
        labels         = { severity = "critical" }
        equation       = "gt"
        no_data_state  = "OK",
        exec_err_state = "OK"
        annotations = {
          summary = "High error rate detected in frontend logs"
        }
      },
      {
        name       = "High error count"
        datasource = "Loki"
        type       = "log"
        expr       = "count_over_time({app=\"web\"} |= \"ERROR\" [5m])"
        threshold  = 50
        labels     = { severity = "critical", service = "web" }
        equation   = "gt"
        annotations = {
          summary = "More than 50 errors in 5 minutes"
          runbook = "Check app logs for stack traces"
        }
      },
      {
        name       = "Error rate spike"
        datasource = "Loki"
        type       = "log"
        expr       = "rate({app=\"backend\"} |= \"error\" [1m])"
        threshold  = 0.1 # i.e., more than 0.1 log lines/sec
        labels     = { severity = "warning" }
        equation   = "gt"
        annotations = {
          summary = "Backend error rate > 0.1 logs/sec for 5m"
        }
      },
      {
        name       = "Per-service error anomaly"
        datasource = "Loki"
        type       = "log"
        expr       = "sum by (app) (rate({environment=\"prod\"} |= \"ERROR\" [5m]))"
        threshold  = 0.5
        labels     = { severity = "high", team = "ops" }
        equation   = "gt"
        annotations = {
          summary     = "Error rate > 0.5/sec detected in at least one service"
          description = "Investigate app with highest error rate in production."
        }
      },
      {
        name           = "HTTP 500 spike"
        datasource     = "Loki"
        type           = "log"
        expr           = "count_over_time({job=\"nginx\"} |= \"status=500\" [5m])"
        threshold      = 20
        labels         = { severity = "critical", layer = "frontend" }
        equation       = "gt"
        no_data_state  = "OK"
        exec_err_state = "OK"
        annotations = {
          summary = "More than 20 HTTP 500s in 5m"
          runbook = "Check nginx ingress and backend health"
        }
      },
      {
        name       = "High error ratio"
        datasource = "Loki"
        type       = "log"
        expr       = "(sum(rate({app=\"api\"} |= \"ERROR\" [5m])) / sum(rate({app=\"api\"} [5m]))) * 100"
        threshold  = 10 # alert if >10% of logs are errors
        labels     = { severity = "critical", service = "api" }
        equation   = "gt"
        annotations = {
          summary     = "Error ratio above 10% for 10m"
          description = "API producing too many error logs relative to total traffic"
        }
      },
      {
        name       = "Risk Declaration Service 500 Error Flood"
        datasource = "Loki-Prod"
        type       = "log"

        # Loki metric query: counts 500 errors for specific WKZ request within 10m
        expr = <<-EOT
          count_over_time(
            {service_name="risk-declaration-service"}
            |~ "/wkz/request"
            |~ "500"
            |~ "http://ai-cfm-wkz-training"
            | level="error"
            [10m]
          )
        EOT

        threshold = 5
        labels = {
          severity     = "critical"
          service_name = "risk-declaration-service"
          environment  = "production"
        }
        equation       = "gt"
        no_data_state  = "OK"
        exec_err_state = "OK"

        annotations = {
          summary     = "Risk Declaration Service is returning 500 errors for WKZ requests"
          description = "More than 5 '500' error logs found in 10 minutes matching WKZ pattern on ai-cfm-wkz-training."
          runbook     = "Check upstream WKZ training endpoint or risk-declaration-service backend health."
        }
      }
    ]
  }

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

      hosts = ["grafana.example.com"]
      annotations = {
        "alb.ingress.kubernetes.io/certificate-arn" = "cert_arn",
        "alb.ingress.kubernetes.io/group.name"      = "dev-ingress"
      }
    }
  }

  tempo = {
    enabled = false
  }

  loki = {
    enabled = true
  }

  prometheus = {
    enabled      = false
    storage_size = "10Gi"

  }
  grafana_admin_password = "admin"
}
