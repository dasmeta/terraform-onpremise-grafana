module "this" {
  source = "../.."

  name = "Test-dashboard"

  application_dashboard = {
    rows : [
      { type : "block/sla" },
      { type : "block/ingress" },
      { type : "block/service", name : "backend", host : "api.example.com" },
      { type : "block/service", name : "worker" }
    ]
    data_source = {
      uid : "#######"
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

  grafana_configs = {

    resources = {
      request = {
        cpu = "1"
        mem = "2Gi"
      }
    }
    ingress = {
      type        = "nginx"
      tls_enabled = true
      public      = true
      # alb_certificate = "cert_arn"

      hosts = ["grafana.example.com"]
      # annotations = {
      #   "alb.ingress.kubernetes.io/group.name"       = "dev-ingress"
      # }
    }
    datasources = [{ type = "cloudwatch", name = "Cloudwatch" }]

  }

  tempo_configs = {
    enabled         = false
    storage_backend = "s3"
    bucket_name     = "my-tempo-traces-kauwnw"
    # tempo_role_arn    = "arn:aws:iam::12345678901:role/tempo-s3-access-manual" # if the role arn is provided then a role will not be created
    oidc_provider_arn = "arn:aws:iam::123456789012:oidc-provider/oidc.eks.<aws_region>.amazonaws.com/id/#######"

    enable_metrics_generator = true
    enable_service_monitor   = true

    persistence = {
      enabled       = true
      size          = "10Gi"
      storage_class = "gp2"
    }
  }

  loki_configs = {
    enabled = false
  }

  prometheus_configs = {
    enabled = false
  }
  grafana_admin_password = "admin"
  aws_region             = "us-east-2"
}
