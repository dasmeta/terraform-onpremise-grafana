module "this" {
  source = "../.."

  application_dashboard = [{
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
  }]

  grafana = {
    resources = {
      requests = {
        cpu    = "1"
        memory = "1Gi"
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

    trace_log_mapping = {
      enabled       = true
      trace_pattern = "trace_id"
    }
  }

  loki_stack = {
    enabled = true
    loki = {
      limits_config = {
        volume_enabled = true
      }
    }
    promtail = {
      ignored_namespaces = ["kube-system", "monitoring"]
      ignored_containers = ["loki", "manager"]
      extra_pipeline_stages = [
        {
          match = {
            selector = "{namespace=~\"external-api-.*\"}"
            stages = [
              {
                json = {
                  expressions = { log = "message" }
                }
              },
              {
                regex = {
                  expression = "(kube-probe|health|prometheus|liveness|ELB-HealthChecker|Amazon-Route53-Health-Check-Service|AUDIT-LOG)"
                  source     = "log"
                }
              },
              {
                drop = { expression = "true" }
              }
            ]
          }
        }
      ]
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

  tempo = {
    enabled         = true
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
  prometheus = {
    enabled = true
  }
  grafana_admin_password = "admin"
}
