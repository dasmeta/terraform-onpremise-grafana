output "folder" {
  value       = try(grafana_folder.this, data.grafana_folder.this)
  description = "The grafana alert rule folder data"
}

output "rule_group" {
  value       = grafana_rule_group.this
  description = "The grafana alert rule group data"
}
