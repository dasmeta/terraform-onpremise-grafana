module "this" {
  source = "../.."

  name         = "Test-dashboard"
  cluster_name = "eks-dev"

  application_dashboard = {
    rows : [
      # { type : "block/sla" },
      # { type : "block/json-file", file: "../." },
      # { type : "container"},
      # { type : "container/network", width : 6 },
      # { type : "block/ingress" },
      { type : "block/cloudwatch", region : "us-east-2" }
    ]
    data_source = {
      uid : "cloudwatch"
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
  # alerts = {
  #   rules = [
  #     {
  #       "datasource" : "prometheus",
  #       "equation" : "gt",
  #       "expr" : "avg(increase(nginx_ingress_controller_request_duration_seconds_sum[3m])) / 10",
  #       "folder_name" : "Nginx Alerts",
  #       "function" : "mean",
  #       "name" : "Latency P1",
  #       "labels" : {
  #         "priority" : "P1",
  #       }
  #       "threshold" : 3

  #       # we override no-data/exec-error state for this example/test only, it is supposed this values will not be set here so they get their default ones
  #       "no_data_state" : "OK"
  #       "exec_err_state" : "OK"
  #       # "exec_err_state" : "Alerting" # uncomment to trigger new alert
  #     },
  #     {
  #       "datasource" : "prometheus",
  #       "equation" : "gt",
  #       "expr" : "avg(increase(nginx_ingress_controller_request_duration_seconds_sum[3m])) / 10",
  #       "folder_name" : "Nginx Alerts",
  #       "function" : "mean",
  #       "name" : "Latency P2",
  #       "labels" : {
  #         "priority" : "P2",
  #       }
  #       "threshold" : 3

  #       # we override no-data/exec-error state for this example/test only, it is supposed this values will not be set here so they get their default ones
  #       "no_data_state" : "OK"
  #       "exec_err_state" : "OK"
  #       # "exec_err_state" : "Alerting" # uncomment to trigger new alert
  #     }
  #   ]
  # }

  grafana_configs = {

    resources = {
      request = {
        cpu = "1"
        mem = "2Gi"
      }
    }
    ingress = {
      type            = "alb"
      tls_enabled     = true
      public          = true
      alb_certificate = "arn:aws:acm:us-east-2:774305617028:certificate/0c7b32a5-cfd3-488b-800c-fe289f3bb040"

      hosts = ["grafana.dev.trysela.com"]
      annotations = {
        "alb.ingress.kubernetes.io/group.name" = "dev-ingress"
      }
    }
    datasources = [{ type = "cloudwatch", name = "Cloudwatch" }]

    # redundency = {
    #   enabled      = true
    #   max_replicas = 3
    #   min_replicas = 2
    # }

  }

  tempo_configs = {
    enabled         = false
    storage_backend = "s3"
    bucket_name     = "my-tempo-traces-kauwnw"
    # tempo_role_arn    = "arn:aws:iam::12345678901:role/tempo-s3-access-manual" # if the role arn is provided then a role will not be created
    cluster_name = "eks-dev"

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

  loki_configs = {
    enabled = false
  }

  prometheus_configs = {
    enabled = true
  }
  grafana_admin_password = "admin"
  aws_region             = "us-east-2"
}

# output "outputs" {
#   value = module.this.grafana
# }

output "dashboard" {
  value = module.this.dashboards
}

# output "base_widget" {
#   value = module.base.data
# }

module "base" {
  source = "../../modules/dashboard/modules/widgets/base"

  cloudwatch_targets = [{
    datasource_uid = "cloudwatch"
  }]

  data_source = {
    type = "cloudwatch"
    uid  = "cloudwatch"
  }
  coordinates = {
    height = 5
    width  = 4
    x      = 8
    y      = 8
  }
  name = "custom-widget"
}

# resource "grafana_dashboard" "name" {
#   config_json = jsonencode(module.base.data)


# }
