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

  default_alert_datasource_uid  = var.victoria_metrics.enabled ? "victoriametrics" : "prometheus"
  disk_capacity_alert_config    = var.alerts.disk_capacity
  disk_capacity_alert_enabled   = coalesce(local.disk_capacity_alert_config.enabled, true)
  disk_capacity_alert_threshold = coalesce(local.disk_capacity_alert_config.threshold, 90)
  disk_capacity_alert_namespace = coalesce(local.disk_capacity_alert_config.namespace, ".*")
  disk_capacity_alert_pvc       = coalesce(local.disk_capacity_alert_config.pvc, ".*")
  disk_capacity_alert_rules = local.disk_capacity_alert_enabled ? [
    {
      name        = "Persistent volume disk usage is above ${local.disk_capacity_alert_threshold}%"
      folder_name = try(coalesce(local.disk_capacity_alert_config.folder_name, var.alerts.folder_name), null)
      group       = coalesce(local.disk_capacity_alert_config.group, "storage")
      datasource  = coalesce(local.disk_capacity_alert_config.datasource, local.default_alert_datasource_uid)
      datasource_type = coalesce(
        local.disk_capacity_alert_config.datasource_type,
        "prometheus"
      )
      interval_ms     = coalesce(local.disk_capacity_alert_config.interval_ms, 1000)
      no_data_state   = coalesce(local.disk_capacity_alert_config.no_data_state, "NoData")
      exec_err_state  = coalesce(local.disk_capacity_alert_config.exec_err_state, "Error")
      expr            = "100 * kubelet_volume_stats_used_bytes{namespace=~\"${local.disk_capacity_alert_namespace}\", persistentvolumeclaim=~\"${local.disk_capacity_alert_pvc}\"} / kubelet_volume_stats_capacity_bytes{namespace=~\"${local.disk_capacity_alert_namespace}\", persistentvolumeclaim=~\"${local.disk_capacity_alert_pvc}\"}"
      metric_name     = ""
      metric_function = ""
      metric_interval = ""
      pending_period  = coalesce(local.disk_capacity_alert_config.pending_period, "5m")
      function        = coalesce(local.disk_capacity_alert_config.function, "last")
      equation        = "gt"
      threshold       = local.disk_capacity_alert_threshold
      condition       = null
      filters         = {}
      settings_mode   = coalesce(local.disk_capacity_alert_config.settings_mode, "replaceNN")
      settings_replaceWith = coalesce(
        local.disk_capacity_alert_config.settings_replaceWith,
        0
      )
      labels = merge(
        {
          priority   = "P2"
          severity   = "warning"
          source     = "grafana"
          scope      = "global"
          alert_type = "disk_capacity"
        },
        local.disk_capacity_alert_config.labels
      )
      annotations = merge(
        {
          component    = "persistent-volume"
          resource     = "pvc"
          metric       = "disk-usage-percent"
          threshold    = "${local.disk_capacity_alert_threshold}%"
          issue_phrase = "PVC disk usage high"
          impact       = "Workloads may fail writes when persistent volume capacity is exhausted."
        },
        local.disk_capacity_alert_config.annotations
      )
    }
  ] : []
  alert_rules = concat(local.disk_capacity_alert_rules, coalesce(var.alerts.rules, []))

  # Extract all unique folder names when using centralized approach
  all_folder_names = var.skip_folder_creation ? [] : distinct(compact(concat(
    # Dashboard folders (these are also used for dashboard submodule alerts)
    [for dashboard in var.application_dashboard : dashboard.folder_name if try(dashboard.folder_name, null) != null],
    # Main alerts module folder names
    [for rule in local.alert_rules : rule.folder_name if try(rule.folder_name, null) != null]
  )))

  folder_name_uids = {
    for name, folder in grafana_folder.shared_folders : name => folder.uid
  }

  json_dashboards = concat(var.dashboards_json_files, var.deploy_grafana_stack_dashboard ? ["${path.module}/grafana_dashboard_files/grafana_stack_dashboard.json"] : [])
}
