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

  application_dashboard = [
    {
      name = "example-service"
      rows = [
        {
          type      = "block/service"
          name      = "api"
          namespace = "default"
          log_widgets = {
            enabled = false
          }
          disk_widgets = {
            enabled = false
          }
        }
      ]
    }
  ]
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

output "dashboard_metric_datasource_uids" {
  value = [
    for panel in module.this.application_dashboards["example-service"].widget_result :
    panel.datasource.uid
    if try(panel.datasource.type, null) == "prometheus"
  ]

  precondition {
    condition = length([
      for panel in module.this.application_dashboards["example-service"].widget_result :
      panel.datasource.uid
      if try(panel.datasource.type, null) == "prometheus"
      ]) > 0 && alltrue([
      for panel in module.this.application_dashboards["example-service"].widget_result :
      panel.datasource.uid == "victoriametrics"
      if try(panel.datasource.type, null) == "prometheus"
    ])
    error_message = "Expected generated dashboard metric widgets to use the VictoriaMetrics datasource."
  }
}

output "dashboard_alert_datasource_uids" {
  value = [
    for rule in module.this.widget_alert_rules :
    rule.datasource
  ]

  precondition {
    condition = length(module.this.widget_alert_rules) > 0 && alltrue([
      for rule in module.this.widget_alert_rules :
      rule.datasource == "victoriametrics"
    ])
    error_message = "Expected generated dashboard block alerts to use the VictoriaMetrics datasource."
  }
}
