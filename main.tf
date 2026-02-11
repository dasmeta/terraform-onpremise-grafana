
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

  count = length(var.alerts.rules) > 0 ? 1 : 0

  alert_interval_seconds = var.alerts.alert_interval_seconds
  disable_provenance     = var.alerts.disable_provenance
  create_folder          = var.skip_folder_creation
  folder_name            = coalesce(var.alerts.folder_name, try(var.application_dashboard[0].folder_name, null), local.app_dash_defaults.folder_name)
  group                  = var.alerts.group
  rules                  = var.alerts.rules
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

  chart_version          = var.grafana.chart_version
  release_name           = var.grafana.release_name
  grafana_admin_password = var.grafana_admin_password
  configs                = var.grafana
  extra_configs          = var.grafana.extra_configs
  mysql_extra_configs    = var.grafana.mysql_extra_configs
  namespace              = coalesce(var.grafana.namespace, var.namespace)
  create_namespace       = var.grafana.create_namespace
  sso_settings           = var.grafana.sso_settings

  datasources = concat(
    var.grafana.datasources == null ? [] : var.grafana.datasources,
    var.prometheus.enabled ? [{ type = "prometheus", name = "Prometheus", url = "http://${var.prometheus.release_name}-kube-prometheus-prometheus.${var.namespace}.svc.cluster.local:9090" }] : [],
    var.tempo.enabled ? [{ type = "tempo", name = "Tempo", url = "http://${var.tempo.release_name}.${var.namespace}.svc.cluster.local:3200" }] : [],
    var.loki_stack.enabled ? [{ type = "loki", name = "Loki", url = "http://${var.loki_stack.loki.release_name}.${var.namespace}.svc.cluster.local:3100" }] : []
  )
}

module "prometheus" {
  source = "./modules/prometheus"

  count = var.prometheus.enabled ? 1 : 0

  chart_version    = var.prometheus.chart_version
  release_name     = var.prometheus.release_name
  configs          = var.prometheus
  extra_configs    = var.prometheus.extra_configs
  namespace        = coalesce(var.prometheus.namespace, var.namespace)
  create_namespace = var.prometheus.create_namespace
}

module "tempo" {
  source = "./modules/tempo"

  count = var.tempo.enabled ? 1 : 0

  chart_version    = var.tempo.chart_version
  release_name     = var.tempo.release_name
  configs          = var.tempo
  extra_configs    = var.tempo.extra_configs
  namespace        = coalesce(var.tempo.namespace, var.namespace)
  create_namespace = var.tempo.create_namespace
}

module "loki" {
  source = "./modules/loki-stack"

  count = var.loki_stack.enabled ? 1 : 0

  configs          = var.loki_stack
  namespace        = coalesce(var.loki_stack.namespace, var.namespace)
  create_namespace = var.loki_stack.create_namespace
}
