module "this" {
  source = "../.."

  skip_folder_creation = true

  alerts = {
    disk_capacity = {
      enabled        = true
      threshold      = 90
      pending_period = "5m"
      namespace      = ".*"
      pvc            = ".*"
      labels = {
        priority = "P2"
        severity = "warning"
        source   = "grafana"
      }
      annotations = {
        component    = "persistent-volume"
        resource     = "pvc"
        metric       = "disk-usage-percent"
        threshold    = "90%"
        issue_phrase = "PVC disk usage high"
        impact       = "Workloads may fail writes when persistent volume capacity is exhausted."
      }
    }
  }

  grafana = {
    enabled = false
  }

  prometheus = {
    enabled = false
  }

  victoria_metrics = {
    enabled = true
  }

  tempo = {
    enabled = false
  }

  loki_stack = {
    enabled = false
  }

  application_dashboard          = []
  dashboards_json_files          = []
  deploy_grafana_stack_dashboard = false
}

output "alerts" {
  value = module.this.alerts

  precondition {
    condition     = length(module.this.alerts) > 0
    error_message = "Expected the module to generate the global disk-capacity alert rule."
  }
}
