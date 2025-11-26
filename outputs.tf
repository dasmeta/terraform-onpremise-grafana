output "folder_uids" {
  value       = local.folder_name_uids
  description = "Map of folder names to folder UIDs for use by external modules"
}

output "grafana_url" {
  value       = try(module.grafana[0].grafana_url, "")
  description = "The URL of the Grafana instance"
}

output "grafana_admin_password" {
  value       = var.grafana_admin_password
  description = "The admin password for Grafana"
  sensitive   = true
}

output "alerts" {
  value       = try(module.alerts[0].rule_groups, {})
  description = "Information about created alert rule groups"
}


output "widget_alert_rules" {
  value       = try(values(module.application_dashboard)[0].widget_alert_rules, [])
  description = "Information about created widget alert rules"
}

output "blocks_by_type" {
  value = try(values(module.application_dashboard)[0].blocks_by_type, {})
}

output "all_folder_names" {
  value       = local.folder_name_uids
  description = "All folder names and uids"
}

output "service_alert_defaults" {
  value = try(values(module.application_dashboard)[0].service_alert_defaults, {})
}

output "service_alert_configs" {
  value = try(values(module.application_dashboard)[0].service_alert_configs, {})
}

output "application_dashboards" {
  value       = module.application_dashboard
  description = "application_dashboard sub-module outputs"
}

output "grafana" {
  value       = try(module.grafana[0], null)
  description = "grafana sub-module outputs"
}

output "prometheus" {
  value       = try(module.prometheus[0], null)
  description = "prometheus sub-module outputs"
}

output "tempo" {
  value       = try(module.tempo[0], null)
  description = "tempo sub-module outputs"
}

output "loki" {
  value       = try(module.loki[0], null)
  description = "loki sub-module outputs"
}
