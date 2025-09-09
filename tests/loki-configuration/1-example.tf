module "this" {
  source = "../.."

  application_dashboard = [{
    name = "Loki-test"
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
  }

  loki = {
    enabled = true
    loki = {
      volume_enabled = true
      send_logs_s3 = {
        enable = true
      }
      schema_configs = [{
        from         = "2023-01-01"
        store        = "boltdb-shipper"
        object_store = "filesystem"
        schema       = "v12"
        index = {
          prefix = "index_"
          period = "24h"
        }
      }]
      storage_configs = {
        tsdb_shipper = {
          active_index_directory = "/data/loki/index"
          cache_location         = "/data/loki/index_cache"
        }
        aws = {
          bucketnames      = "mycustomlokibucket-djalsd"
          region           = "us-east-2"
          s3forcepathstyle = true
        }
      }
      service_account = {
        annotations = {
          "eks.amazonaws.com/role-arn-test" = "test-annotation-value"
        }
      }
      retention_period = "12h"

      replicas = 2
    }
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

  prometheus = {
    enabled = true
  }
  grafana_admin_password = "admin"
}
