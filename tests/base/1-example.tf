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
    prometheus_url = "http://prometheus-operated.monitoring.svc.cluster.local:9090"

    resources = {
      request = {
        cpu = "1"
        mem = "2Gi"
      }
    }
    ingress_configs = {
      annotations = {
        "kubernetes.io/ingress.class"                = "alb"
        "alb.ingress.kubernetes.io/scheme"           = "internet-facing"
        "alb.ingress.kubernetes.io/target-type"      = "ip"
        "alb.ingress.kubernetes.io/listen-ports"     = "[{\\\"HTTP\\\": 80}, {\\\"HTTPS\\\": 443}]"
        "alb.ingress.kubernetes.io/group.name"       = "dev-ingress"
        "alb.ingress.kubernetes.io/healthcheck-path" = "/api/health"
        "alb.ingress.kubernetes.io/ssl-redirect"     = "443"
        "alb.ingress.kubernetes.io/certificate-arn"  = "certificate_arn"
      }
      hosts = ["grafana.example.com"]
    }
  }

  tempo_configs = {
    enabled           = true
    storage_backend   = "s3"
    bucket_name       = "my-tempo-traces-kauwnw"
    oidc_provider_arn = "oidc_provider_arn"

    enable_metrics_generator = true
    enable_service_monitor   = true

    persistence = {
      enabled       = true
      size          = "10Gi"
      storage_class = "gp2"
    }

    ingress = {
      enabled = true
      annotations = {
        "kubernetes.io/ingress.class"                = "nginx"
        "nginx.ingress.kubernetes.io/rewrite-target" = "/"
        "nginx.ingress.kubernetes.io/ssl-redirect"   = "true"
      }
      hosts     = ["tempo.example.com"]
      path      = "/"
      path_type = "Prefix"
    }
  }

  grafana_admin_password = "admin"
  aws_region             = "us-east-2"
}
