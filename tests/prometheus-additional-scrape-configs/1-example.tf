module "this" {
  source = "../.."

  grafana = {
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
  }

  tempo = {
    enabled = false
  }

  loki_stack = {
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
