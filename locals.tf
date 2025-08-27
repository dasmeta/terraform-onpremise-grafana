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
  all_folder_names = var.skip_folder_creation ? [] : distinct(concat(
    [for dashboard in var.application_dashboard : dashboard.folder_name],
    [for rule in try(var.alerts.rules, []) : rule.folder_name if rule.folder_name != null],
    var.alerts.folder_name != null ? [var.alerts.folder_name] : []
  ))

  folder_uids = {
    for name, folder in grafana_folder.shared_folders : name => folder.uid
  }
}
