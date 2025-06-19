module "this" {
  source = "../.."

  name         = "Loki-test"
  cluster_name = "eks-dev"

  application_dashboard = {
    rows : [
      { type : "block/service", name = "worker", show_err_logs = true, expr = "{pod=~\"worker.*\"}" },
    ]
    data_source = {
      uid : "loki"
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

  grafana_configs = {
    resources = {
      request = {
        cpu = "1"
        mem = "1Gi"
      }
    }
    ingress = {
      type            = "alb"
      tls_enabled     = true
      public          = true
      alb_certificate = "cert_arn"

      hosts = ["grafana.example.com"]
      annotations = {
        "alb.ingress.kubernetes.io/group.name" = "dev-ingress"
      }
    }
    # datasources = [{ type = "cloudwatch", name = "Cloudwatch" }]
  }

  loki_configs = {
    enabled = true
    promtail = {
      ignored_namespaces = ["kube-system", "monitoring"]
      ignored_containers = ["loki", "manager"]
      extra_scrape_configs = [
        {
          job_name = "test-scrape-job"
          kubernetes_sd_configs = [
            { role = "pod" }
          ]
          relabel_configs = [
            {
              source_labels = ["__meta_kubernetes_pod_name"]
              regex         = ".*"
              target_label  = "env"
              replacement   = "test-scrape"
            },
            {
              source_labels = [
                "__meta_kubernetes_pod_uid",
                "__meta_kubernetes_pod_container_name"
              ]
              separator    = "/"
              target_label = "__path__"
              replacement  = "/var/log/pods/*$1/*.log"
              action       = "replace"
            }
          ]
          pipeline_stages = [
            {
              json = {
                expressions = {
                  msg = "message"
                }
              }
            },
            {
              timestamp = {
                source = "time"
                format = "RFC3339"
              }
            }
          ]
        }
      ]
    }
  }

  prometheus_configs = {
    enabled = true
  }
  grafana_admin_password = "admin"
  aws_region             = "us-east-2"
}

output "dashboard" {
  value = module.this.dashboards
}
