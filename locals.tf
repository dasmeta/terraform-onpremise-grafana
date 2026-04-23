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
    [for dashboard in var.application_dashboard : dashboard.folder_name if try(dashboard.folder_name, null) != null],
    # Main alerts module folder names
    [for rule in try(var.alerts.rules, []) : rule.folder_name if try(rule.folder_name, null) != null]
  )))

  folder_name_uids = {
    for name, folder in grafana_folder.shared_folders : name => folder.uid
  }

  victoria_metrics_namespace = coalesce(var.victoria_metrics.namespace, var.namespace)
  victoria_metrics_remote_write_url = format(
    "http://%s-victoria-metrics-cluster-vminsert.%s.svc.cluster.local:8480/insert/0/prometheus/api/v1/write",
    var.victoria_metrics.release_name,
    local.victoria_metrics_namespace
  )
  victoria_metrics_query_url = format(
    "http://%s-victoria-metrics-cluster-vmselect.%s.svc.cluster.local:8481/select/0/prometheus",
    var.victoria_metrics.release_name,
    local.victoria_metrics_namespace
  )

  prometheus_remote_write_config = var.victoria_metrics.enabled ? {
    prometheus = {
      prometheusSpec = {
        remoteWrite = [{
          url = local.victoria_metrics_remote_write_url
        }]
      }
    }
  } : {}

  json_dashboards = concat(var.dashboards_json_files, var.deploy_grafana_stack_dashboard ? ["${path.module}/grafana_dashboard_files/grafana_stack_dashboard.json"] : [])
}
