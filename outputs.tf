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
  value       = try(module.application_dashboard[0].widget_alert_rules, [])
  description = "Information about created widget alert rules"
}

output "blocks_by_type" {
  value = try(module.application_dashboard[0].blocks_by_type, {})
}

output "all_folder_names" {
  value       = local.folder_name_uids
  description = "All folder names and uids"
}

# output "prometheus_debug" {
#   value       = try(module.prometheus[0].debug_configs, {})
#   description = "Debug: Prometheus module configs"
# }

# output "prometheus_additional_scrape_configs" {
#   value       = try(module.prometheus[0].additional_scrape_configs, [])
#   description = "Debug: Additional scrape configs passed to Prometheus"
# }
