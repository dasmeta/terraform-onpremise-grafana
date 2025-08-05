module "this" {
  source = "../.."

  name = "Test-dashboard"

  application_dashboard = {
    rows : [
      # { type : "block/service", name = "worker", show_err_logs = true },
    ]
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
  alerts = {
    rules = [
      {
        "datasource" : "prometheus",
        "equation" : "gt",
        "expr" : "avg(increase(nginx_ingress_controller_request_duration_seconds_sum[3m])) / 10",
        "folder_name" : "Nginx Alerts",
        "function" : "mean",
        "name" : "Latency P1",
        "labels" : {
          "priority" : "P1",
        }
        "threshold" : 3

        # we override no-data/exec-error state for this example/test only, it is supposed this values will not be set here so they get their default ones
        "no_data_state" : "OK"
        "exec_err_state" : "OK"
        # "exec_err_state" : "Alerting" # uncomment to trigger new alert
      },
      {
        "datasource" : "prometheus",
        "equation" : "gt",
        "expr" : "avg(increase(nginx_ingress_controller_request_duration_seconds_sum[3m])) / 10",
        "folder_name" : "Nginx Alerts",
        "function" : "mean",
        "name" : "Latency P2",
        "labels" : {
          "priority" : "P2",
        }
        "threshold" : 3

        # we override no-data/exec-error state for this example/test only, it is supposed this values will not be set here so they get their default ones
        "no_data_state" : "OK"
        "exec_err_state" : "OK"
        # "exec_err_state" : "Alerting" # uncomment to trigger new alert
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

      hosts = ["grafana.dev.trysela.com"]
      annotations = {
        "alb.ingress.kubernetes.io/certificate-arn" = "cert_arn",
        "alb.ingress.kubernetes.io/group.name"      = "dev-ingress"
      }
    }
    trace_log_mapping = {
      enabled = true
    }
  }

  tempo = {
    enabled = true

    metrics_generator = {
      enabled = true
    }
    enable_service_monitor = true

    persistence = {
      enabled       = true
      size          = "10Gi"
      storage_class = "gp2"
    }
  }

  loki = {
    enabled = true
  }

  prometheus = {
    enabled = true
  }
  grafana_admin_password = "admin"
  # dashboards_json_files = [
  #   "./dashboard_files/ALB_dashboard.json",
  #   "./dashboard_files/Application_main_dashboard.json"
  # ]
}
