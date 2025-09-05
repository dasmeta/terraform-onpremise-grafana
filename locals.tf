locals {
  app_dash_defaults = {
    folder_name = "application-dashboard"
    rows        = []
    data_source = { uid = "prometheus", type = "prometheus" }
    variables   = []
    alerts      = { enabled = true }
  }

  # Fill defaults
  app_dash_list = [
    for d in var.application_dashboard :
    merge(local.app_dash_defaults, d)
  ]

  # Key by name and skip ones with no rows (replicates your old count behavior)
  app_dash_map = {
    for d in local.app_dash_list : d.name => d
    if length(try(d.rows, [])) > 0
  }

  # Extract all unique folder names when using centralized approach
  all_folder_names = var.skip_folder_creation ? [] : distinct(compact(concat(
    # Dashboard folders (these are also used for dashboard submodule alerts)
    [for dashboard in var.application_dashboard : dashboard.folder_name if dashboard.folder_name != null],
    # Main alerts module folder names
    [for rule in try(var.alerts.rules, []) : rule.folder_name if rule.folder_name != null]
  )))

  folder_name_uids = {
    for name, folder in grafana_folder.shared_folders : name => folder.uid
  }

  json_dashboards = concat(var.dashboards_json_files, [var.deploy_grafana_stack_dashboard ? "${path.module}/grafana_dashboard_files/grafana_stack_dashboard.json" : ""])
}
