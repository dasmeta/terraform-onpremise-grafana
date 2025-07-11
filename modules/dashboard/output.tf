
output "rows" {
  value = local.rows
}

output "widget_result" {
  value = local.widget_result
}

output "blocks_results" {
  value = local.blocks_results
}

output "widget_alert_rules" {
  value = local.widget_alert_rules
}

output "folder" {
  value = grafana_folder.this.uid
}
