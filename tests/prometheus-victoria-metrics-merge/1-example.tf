module "this" {
  source = "../.."

  grafana = {
    enabled = false
  }

  alerts = {
    disk_capacity = {
      enabled = false
    }
  }

  prometheus = {
    enabled = true
    extra_configs = {
      prometheus = {
        prometheusSpec = {
          nodeSelector = { workload = "monitoring" }
          tolerations = [{
            key      = "workload"
            operator = "Equal"
            value    = "monitoring"
            effect   = "NoSchedule"
          }]
        }
      }
    }
  }

  victoria_metrics = {
    enabled = true
  }
}
