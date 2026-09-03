locals {
  metrics_collector = var.metrics_collector

  prometheus_scraping_enabled    = local.metrics_collector == "prometheus"
  victoria_metrics_agent_enabled = local.metrics_collector == "victoria_metrics"
  prometheus_converter_enabled   = var.prometheus.enabled && var.victoria_metrics.enabled
  victoria_metrics_standalone = (
    local.victoria_metrics_agent_enabled &&
    var.victoria_metrics.enabled &&
    !var.prometheus.enabled
  )
  default_metrics_datasource_uid = local.metrics_collector == "victoria_metrics" ? "victoriametrics" : "prometheus"
  default_metrics_data_source    = { uid = local.default_metrics_datasource_uid, type = "prometheus" }

  victoria_metrics_agent_caller_scrape_configs = (
    var.victoria_metrics.agent.extra_scrape_configs == null
    ? []
    : var.victoria_metrics.agent.extra_scrape_configs
  )
  victoria_metrics_agent_has_kube_state_metrics_scrape_config = try(anytrue([
    for scrape_config in local.victoria_metrics_agent_caller_scrape_configs :
    try(scrape_config.job_name, "") == "kube-state-metrics"
  ]), false)

  kube_state_metrics_namespace = coalesce(
    var.kube_state_metrics.namespace,
    var.prometheus.namespace,
    var.namespace
  )
  kube_state_metrics_fullname = coalesce(
    var.kube_state_metrics.fullname_override,
    "${var.prometheus.release_name}-kube-state-metrics"
  )
  kube_state_metrics_service_target = format(
    "%s.%s.svc.cluster.local:8080",
    local.kube_state_metrics_fullname,
    local.kube_state_metrics_namespace
  )
  kube_state_metrics_prometheus_monitor_enabled = (
    var.kube_state_metrics.enabled &&
    var.prometheus.enabled &&
    local.prometheus_scraping_enabled
  )
  kube_state_metrics_vm_service_scrape_enabled = (
    var.kube_state_metrics.enabled &&
    var.victoria_metrics.enabled &&
    local.victoria_metrics_agent_enabled &&
    !local.victoria_metrics_agent_has_kube_state_metrics_scrape_config
  )

  node_exporter_namespace = coalesce(
    var.node_exporter.namespace,
    var.prometheus.namespace,
    var.namespace,
  )
  node_exporter_fullname = coalesce(
    var.node_exporter.fullname_override,
    "prometheus-node-exporter",
  )
  node_exporter_service_target = format(
    "%s.%s.svc.cluster.local:9100",
    local.node_exporter_fullname,
    local.node_exporter_namespace,
  )
  node_exporter_prometheus_monitor_enabled = (
    var.node_exporter.enabled &&
    var.prometheus.enabled &&
    local.prometheus_scraping_enabled
  )
  node_exporter_vm_service_scrape_enabled = (
    var.node_exporter.enabled &&
    var.victoria_metrics.enabled &&
    local.victoria_metrics_agent_enabled
  )

  app_dash_defaults = {
    folder_name = "application-dashboard"
    defaults = {
      prometheus = {
        datasource_uid = local.default_metrics_datasource_uid
      }
    }
    rows        = []
    data_source = local.default_metrics_data_source
    variables   = []
    alerts      = { enabled = true }
  }

  # Fill defaults
  app_dash_list = [
    for d in var.application_dashboard :
    merge(local.app_dash_defaults, d, {
      defaults = merge(
        local.app_dash_defaults.defaults,
        try(d.defaults, {}),
        {
          prometheus = merge(
            local.app_dash_defaults.defaults.prometheus,
            try(d.defaults.prometheus, {})
          )
        }
      )
      data_source = {
        uid  = coalesce(try(d.data_source.uid, null), local.default_metrics_datasource_uid)
        type = coalesce(try(d.data_source.type, null), "prometheus")
      }
    })
  ]

  # Key by name and skip ones with no rows (replicates your old count behavior)
  app_dash_map = {
    for d in local.app_dash_list : d.name => d
    if length(try(d.rows, [])) > 0
  }

  victoria_metrics_namespace = coalesce(var.victoria_metrics.namespace, var.namespace)
  victoria_metrics_vminsert_service_name = trimsuffix(substr(
    "${var.victoria_metrics.release_name}-victoria-metrics-cluster-vminsert",
    0,
    63,
  ), "-")
  victoria_metrics_vmselect_service_name = trimsuffix(substr(
    "${var.victoria_metrics.release_name}-victoria-metrics-cluster-vmselect",
    0,
    63,
  ), "-")
  victoria_metrics_remote_write_url = format(
    "http://%s.%s.svc.cluster.local:8480/insert/0/prometheus/api/v1/write",
    local.victoria_metrics_vminsert_service_name,
    local.victoria_metrics_namespace
  )
  victoria_metrics_query_url = format(
    "http://%s.%s.svc.cluster.local:8481/select/0/prometheus",
    local.victoria_metrics_vmselect_service_name,
    local.victoria_metrics_namespace
  )

  prometheus_remote_write_receiver_url = format(
    "http://%s-kube-prometheus-prometheus.%s.svc.cluster.local:9090/api/v1/write",
    var.prometheus.release_name,
    coalesce(var.prometheus.namespace, var.namespace),
  )
  selected_metrics_remote_write_url = (
    local.metrics_collector == "victoria_metrics"
    ? local.victoria_metrics_remote_write_url
    : local.prometheus_remote_write_receiver_url
  )

  tempo_metrics_generator_remote_write_url = coalesce(
    try(var.tempo.metrics_generator.remote_url, null),
    local.selected_metrics_remote_write_url,
  )
  tempo_metrics_generator_uses_selected_backend = (
    try(var.tempo.metrics_generator.remote_url, null) == null
  )
  tempo_prometheus_monitor_enabled = (
    var.tempo.enabled &&
    var.tempo.enable_service_monitor &&
    var.prometheus.enabled &&
    local.prometheus_scraping_enabled
  )
  tempo_vm_service_scrape_enabled = (
    var.tempo.enabled &&
    var.tempo.enable_service_monitor &&
    var.victoria_metrics.enabled &&
    local.victoria_metrics_agent_enabled
  )

  loki_namespace = coalesce(var.loki_stack.namespace, var.namespace)
  loki_prometheus_monitor_enabled = (
    var.loki_stack.enabled &&
    var.loki_stack.loki.monitoring.serviceMonitor.enabled &&
    var.prometheus.enabled &&
    local.prometheus_scraping_enabled
  )
  loki_prometheus_rules_enabled = (
    var.loki_stack.enabled &&
    var.prometheus.enabled &&
    local.prometheus_scraping_enabled &&
    try(var.loki_stack.loki.extra_configs.monitoring.rules.enabled, false)
  )
  loki_vm_service_scrape_enabled = (
    var.loki_stack.enabled &&
    var.loki_stack.loki.monitoring.serviceMonitor.enabled &&
    var.victoria_metrics.enabled &&
    local.victoria_metrics_agent_enabled
  )

  grafana_prometheus_monitor_enabled = (
    var.grafana.enabled &&
    var.prometheus.enabled &&
    local.prometheus_scraping_enabled &&
    try(var.grafana.extra_configs.serviceMonitor.enabled, false)
  )

  loki_query_url = var.loki_stack.enabled ? module.loki[0].query_url : ""

  default_alert_datasource_uid  = local.default_metrics_datasource_uid
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
