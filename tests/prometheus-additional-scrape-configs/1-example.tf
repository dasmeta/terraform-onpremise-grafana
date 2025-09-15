module "this" {
  source = "../.."

  # application_dashboard = {
  #     name        = "Test-dashboard",
  #     folder_name = "Test-dashboard",
  #     alerts      = { enabled = false },
  #     rows : [
  #       { type : "block/service", name = "worker", show_err_logs = true, loki_datasource_uid = "loki", namespace = "dev" }
  #     ]
  #     data_source = {
  #       uid = "prometheus"
  #     }

  #     variables = [
  #       {
  #         "name" : "namespace",
  #         "options" : [
  #           {
  #             "value" : "prod"
  #           },
  #           {
  #             "selected" : true,
  #             "value" : "dev"
  #           }
  #         ],
  #       }
  #     ]
  #   }

  # alerts = {
  #   rules = [
  #     {
  #       datasource  = "prometheus",
  #       equation    = "gt",
  #       expr        = "avg(increase(nginx_ingress_controller_request_duration_seconds_sum[3m])) / 10",
  #       folder_name = "Nginx Alerts",
  #       function    = "mean",
  #       name        = "Latency P1",
  #       labels = {
  #         priority = "P1",
  #       },
  #       threshold = 3,
  #       summary   = "This is the summary1",

  #       # we override no-data/exec-error state for this example/test only, it is supposed this values will not be set here so they get their default ones
  #       no_data_state  = "OK",
  #       exec_err_state = "OK"
  #       # "exec_err_state" : "Alerting" # uncomment to trigger new alert
  #     },
  #     {
  #       datasource  = "prometheus",
  #       equation    = "gt",
  #       expr        = "avg(increase(nginx_ingress_controller_request_duration_seconds_sum[3m])) / 10",
  #       folder_name = "Nginx Alerts",
  #       function    = "mean",
  #       name        = "Latency P2",
  #       labels = {
  #         priority = "P2",
  #       },
  #       threshold = 3,
  #       summary   = "This is the summary2",

  #       # we override no-data/exec-error state for this example/test only, it is supposed this values will not be set here so they get their default ones
  #       no_data_state  = "OK",
  #       exec_err_state = "OK"
  #       # "exec_err_state" : "Alerting" # uncomment to trigger new alert
  #     }
  #   ]
  # }

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
        "alb.ingress.kubernetes.io/group.name"      = "ingress_group"
      }
    }
    trace_log_mapping = {
      enabled = true
    }
  }

  tempo = {
    enabled = false
  }

  loki = {
    enabled = false
  }

  prometheus = {
    enabled = true
    additional_scrape_configs = [
      {
        job_name       = "my-extra-job"
        static_configs = [{ targets = ["app-1.metrics.svc:9090"] }]
        metric_relabel_configs = [{
          source_labels = ["__name__"]
          regex         = "^go_.*"
          action        = "drop"
        }]
      },
      {
        job_name              = "sidecar"
        kubernetes_sd_configs = [{ role = "pod" }]
        relabel_configs = [
          {
            action        = "keep"
            source_labels = ["__meta_kubernetes_pod_label_app"]
            regex         = "sidecar"
          }
        ]
      }
    ]
  }
  grafana_admin_password = "admin"

}
