module "this" {
  source = "../.."

  application_dashboard = [
    {
      name        = "Test-dashboard",
      folder_name = "Test-dashboard",
      alerts      = { enabled = false },
      rows : [
        { type : "block/service", name = "worker", show_err_logs = true, loki_datasource_uid = "loki", namespace = "dev" }
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
    },
    {
      name        = "Test-dashboard-2",
      folder_name = "Test-dashboard-2",
      alerts      = { enabled = false },
      rows = [
        { type : "block/service", name = "worker2", show_err_logs = true, loki_datasource_uid = "loki", namespace = "dev" }
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
        datasource  = "prometheus",
        equation    = "gt",
        expr        = "avg(increase(nginx_ingress_controller_request_duration_seconds_sum[3m])) / 10",
        folder_name = "Nginx Alerts",
        function    = "mean",
        name        = "Latency P2",
        labels = {
          priority = "P2",
        },
        threshold = 3,
        summary   = "This is the summary2",

        # we override no-data/exec-error state for this example/test only, it is supposed this values will not be set here so they get their default ones
        no_data_state  = "OK",
        exec_err_state = "OK"
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

      hosts = ["grafana.example.com"]
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
  }

  loki = {
    enabled = true
  }

  prometheus = {
    enabled       = true
    storage_size  = "20Gi"
    storage_class = "gp2"
  }
  grafana_admin_password = "adminPass312"
  dashboards_json_files = [
    "./dashboard_files/ALB_dashboard.json",
    "./dashboard_files/Application_main_dashboard.json"
  ]
}

output "all_folder_names" {
  value = module.this.all_folder_names
}
