output "dashboards" {
  value = {
    application_dashboard = module.application_dashboard
  }
}

output "grafana" {
  value = module.grafana
}

output "alerts" {
  value = concat(var.alerts.rules, try(module.application_dashboard[0].widget_alert_rules, []))
}
