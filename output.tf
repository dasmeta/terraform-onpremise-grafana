output "dashboards" {
  value = {
    application_dashboard = module.application_dashboard
  }
}

output "grafana" {
  value = module.grafana
}
