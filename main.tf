
resource "grafana_folder" "shared_folders" {
  for_each = var.skip_folder_creation && length(local.all_folder_names) > 0 ? toset([]) : toset(local.all_folder_names)
  title    = each.value

  depends_on = [module.grafana]
}

module "application_dashboard" {
  source = "./modules/dashboard/"

  for_each = local.app_dash_map

  name                = each.value.name
  defaults            = each.value.defaults
  folder_name         = each.value.folder_name
  create_folder       = var.skip_folder_creation
  rows                = each.value.rows
  time_range_hours    = try(each.value.time_range_hours, 6)
  data_source         = each.value.data_source
  loki_datasource_uid = each.value.loki_datasource_uid
  variables           = each.value.variables
  alerts              = each.value.alerts
  folder_name_uids    = local.folder_name_uids


  # TODO: there is a bug/issue that brings to count/foreach related error in alert creation submodule when we just change something in grafana/prometheus, so it is recommended to disable alerts and apply things and then enable back alerts, check and fix this issue
  depends_on = [module.grafana, grafana_folder.shared_folders]
}

module "application_dashboard_json" {
  count  = length(local.json_dashboards) > 0 ? 1 : 0
  source = "./modules/dashboard-json"

  dashboard_json_files = local.json_dashboards
  depends_on           = [module.grafana]
}

module "alerts" {
  source = "./modules/alerts"

  count = length(local.alert_rules) > 0 || var.alerts.contact_points != null || var.alerts.notifications != null ? 1 : 0

  alert_interval_seconds = var.alerts.alert_interval_seconds
  disable_provenance     = var.alerts.disable_provenance
  create_folder          = var.skip_folder_creation
  folder_name            = coalesce(var.alerts.folder_name, try(var.application_dashboard[0].folder_name, null), local.app_dash_defaults.folder_name)
  group                  = var.alerts.group
  rules                  = local.alert_rules
  annotations            = var.alerts.annotations
  labels                 = var.alerts.labels
  contact_points         = var.alerts.contact_points
  notifications          = var.alerts.notifications
  folder_name_uids       = local.folder_name_uids

  depends_on = [module.grafana, grafana_folder.shared_folders]
}

module "grafana" {
  source = "./modules/grafana"

  count = var.grafana.enabled ? 1 : 0

  chart_version                  = var.grafana.chart_version
  release_name                   = var.grafana.release_name
  grafana_admin_password         = var.grafana_admin_password
  configs                        = var.grafana
  extra_configs                  = var.grafana.extra_configs
  mysql_extra_configs            = var.grafana.mysql_extra_configs
  namespace                      = coalesce(var.grafana.namespace, var.namespace)
  create_namespace               = var.grafana.create_namespace
  sso_settings                   = var.grafana.sso_settings
  default_metrics_datasource_uid = local.default_metrics_datasource_uid
  prometheus_monitor_enabled     = local.grafana_prometheus_monitor_enabled

  datasources = concat(
    var.grafana.datasources == null ? [] : var.grafana.datasources,
    var.prometheus.enabled ? [{ type = "prometheus", name = "Prometheus", url = "http://${var.prometheus.release_name}-kube-prometheus-prometheus.${coalesce(var.prometheus.namespace, var.namespace)}.svc.cluster.local:9090", is_default = local.metrics_collector == "prometheus" }] : [],
    var.victoria_metrics.enabled ? [{ type = "prometheus", name = "VictoriaMetrics", uid = "victoriametrics", url = local.victoria_metrics_query_url, is_default = local.metrics_collector == "victoria_metrics" }] : [],
    var.tempo.enabled ? [{ type = "tempo", name = "Tempo", url = "http://${var.tempo.release_name}.${var.namespace}.svc.cluster.local:3200" }] : [],
    var.loki_stack.enabled ? [{ type = "loki", name = "Loki", url = local.loki_query_url }] : []
  )
}

module "prometheus" {
  source = "./modules/prometheus"

  count = var.prometheus.enabled ? 1 : 0

  chart_version     = var.prometheus.chart_version
  release_name      = var.prometheus.release_name
  configs           = var.prometheus
  collector_enabled = local.prometheus_scraping_enabled
  remote_write_url = (
    var.victoria_metrics.enabled && local.prometheus_scraping_enabled
    ? local.victoria_metrics_remote_write_url
    : null
  )
  extra_configs    = var.prometheus.extra_configs
  namespace        = coalesce(var.prometheus.namespace, var.namespace)
  create_namespace = var.prometheus.create_namespace
}

module "kube_state_metrics" {
  source = "./modules/kube-state-metrics"

  count = var.kube_state_metrics.enabled ? 1 : 0

  chart_version              = var.kube_state_metrics.chart_version
  release_name               = var.kube_state_metrics.release_name
  namespace                  = local.kube_state_metrics_namespace
  create_namespace           = var.kube_state_metrics.create_namespace
  fullname_override          = local.kube_state_metrics_fullname
  prometheus_monitor_enabled = local.kube_state_metrics_prometheus_monitor_enabled
  prometheus_release_name    = var.prometheus.release_name
  extra_configs              = var.kube_state_metrics.extra_configs

  depends_on = [module.prometheus]
}

module "node_exporter" {
  source = "./modules/node-exporter"

  count = var.node_exporter.enabled ? 1 : 0

  chart_version              = var.node_exporter.chart_version
  release_name               = var.node_exporter.release_name
  namespace                  = local.node_exporter_namespace
  create_namespace           = var.node_exporter.create_namespace
  fullname_override          = local.node_exporter_fullname
  resources                  = var.node_exporter.resources
  prometheus_monitor_enabled = local.node_exporter_prometheus_monitor_enabled
  prometheus_release_name    = var.prometheus.release_name
  extra_configs              = var.node_exporter.extra_configs

  depends_on = [module.prometheus]
}

module "victoria_metrics" {
  source = "./modules/victoria-metrics"

  count = var.victoria_metrics.enabled ? 1 : 0

  chart_version    = var.victoria_metrics.chart_version
  release_name     = var.victoria_metrics.release_name
  configs          = var.victoria_metrics
  extra_configs    = var.victoria_metrics.extra_configs
  namespace        = local.victoria_metrics_namespace
  create_namespace = var.victoria_metrics.create_namespace

  agent_enabled                      = local.victoria_metrics_agent_enabled
  agent_standalone                   = local.victoria_metrics_standalone
  operator_enabled                   = var.victoria_metrics.operator.enabled
  operator_chart_version             = var.victoria_metrics.operator.chart_version
  operator_release_name              = var.victoria_metrics.operator.release_name
  operator_extra_configs             = var.victoria_metrics.operator.extra_configs
  prometheus_converter_enabled       = local.prometheus_converter_enabled
  agent_name                         = var.victoria_metrics.agent.name
  agent_replica_count                = var.victoria_metrics.agent.replica_count
  agent_kubelet_scrape_enabled       = var.victoria_metrics.agent.kubelet_scrape_enabled
  agent_cadvisor_scrape_enabled      = var.victoria_metrics.agent.cadvisor_scrape_enabled
  agent_resource_scrape_enabled      = var.victoria_metrics.agent.resource_scrape_enabled
  agent_kubelet_metrics              = var.victoria_metrics.agent.kubelet_metrics
  agent_kubernetes_component_scrapes = var.victoria_metrics.agent.kubernetes_component_scrapes
  agent_extra_scrape_configs         = var.victoria_metrics.agent.extra_scrape_configs
  agent_extra_configs                = var.victoria_metrics.agent.extra_configs

  agent_kube_state_metrics_enabled      = local.kube_state_metrics_vm_service_scrape_enabled
  agent_kube_state_metrics_namespace    = local.kube_state_metrics_namespace
  agent_kube_state_metrics_release_name = var.kube_state_metrics.release_name
  agent_kube_state_metrics_fullname     = local.kube_state_metrics_fullname

  agent_node_exporter_enabled      = local.node_exporter_vm_service_scrape_enabled
  agent_node_exporter_namespace    = local.node_exporter_namespace
  agent_node_exporter_release_name = var.node_exporter.release_name
  agent_node_exporter_fullname     = local.node_exporter_fullname

  agent_tempo_enabled       = local.tempo_vm_service_scrape_enabled
  agent_tempo_namespace     = coalesce(var.tempo.namespace, var.namespace)
  agent_tempo_release_name  = var.tempo.release_name
  agent_tempo_query_enabled = try(var.tempo.extra_configs.tempoQuery.enabled, false)

  agent_loki_enabled      = local.loki_vm_service_scrape_enabled
  agent_loki_namespace    = local.loki_namespace
  agent_loki_release_name = var.loki_stack.loki.release_name

  depends_on = [
    module.prometheus,
    module.kube_state_metrics,
    module.node_exporter,
  ]
}

module "tempo" {
  source = "./modules/tempo"

  count = var.tempo.enabled ? 1 : 0

  chart_version                = var.tempo.chart_version
  release_name                 = var.tempo.release_name
  configs                      = var.tempo
  extra_configs                = var.tempo.extra_configs
  namespace                    = coalesce(var.tempo.namespace, var.namespace)
  create_namespace             = var.tempo.create_namespace
  metrics_generator_remote_url = local.tempo_metrics_generator_remote_write_url
  service_monitor_enabled      = local.tempo_prometheus_monitor_enabled
}

module "loki" {
  source = "./modules/loki-stack"

  count = var.loki_stack.enabled ? 1 : 0

  configs                    = var.loki_stack
  namespace                  = coalesce(var.loki_stack.namespace, var.namespace)
  create_namespace           = var.loki_stack.create_namespace
  prometheus_monitor_enabled = local.loki_prometheus_monitor_enabled
  prometheus_rules_enabled   = local.loki_prometheus_rules_enabled
}
