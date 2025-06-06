resource "grafana_dashboard" "this" {
  for_each = { for idx, file_path in var.dashboard_json_files : idx => file(file_path) }

  config_json = each.value
}
