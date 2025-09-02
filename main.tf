module "application_dashboard" {
  source = "./modules/dashboard/"

  count = length(var.application_dashboard.rows) > 0 ? 1 : 0

  name        = var.name
  folder_name = var.application_dashboard.folder_name
  rows        = var.application_dashboard.rows
  data_source = var.application_dashboard.data_source
  variables   = var.application_dashboard.variables
  alerts      = var.application_dashboard.alerts

  # TODO: there is a bug/issue that brings to count/foreach related error in alert creation submodule when we just change something in grafana/prometheus, so it is recommended to disable alerts and apply things and then enable back alerts, check and fix this issue
  depends_on = [module.grafana, module.prometheus]
}

module "application_dashboard_json" {
  count  = length(var.dashboards_json_files) > 0 ? 1 : 0
  source = "./modules/dashboard-json"

  dashboard_json_files = var.dashboards_json_files
  depends_on           = [module.grafana, module.prometheus]
}

module "alerts" {
  source = "./modules/alerts"

  count = length(var.alerts) > 0 ? 1 : 0

  alert_interval_seconds = var.alerts.alert_interval_seconds
  disable_provenance     = var.alerts.disable_provenance
  create_folder          = var.alerts.create_folder ? true : (length(var.application_dashboard.rows) > 0 && (var.alerts.folder_name == null || var.alerts.folder_name != var.application_dashboard.folder_name) ? false : true)
  folder_name            = coalesce(var.alerts.folder_name, var.application_dashboard.folder_name)
  group                  = var.alerts.group
  rules                  = var.alerts.rules
  annotations            = var.alerts.annotations
  labels                 = var.alerts.labels
  contact_points         = var.alerts.contact_points
  notifications          = var.alerts.notifications

  depends_on = [module.grafana, module.prometheus, module.application_dashboard]
}

module "grafana" {
  source = "./modules/grafana"

  count = var.grafana.enabled ? 1 : 0

  chart_version          = var.grafana.chart_version
  grafana_admin_password = var.grafana_admin_password
  configs                = var.grafana
  datasources = concat(
    var.grafana.datasources == null ? [] : var.grafana.datasources,
    var.prometheus.enabled ? [{ type = "prometheus", name = "Prometheus" }] : [],
    var.tempo.enabled ? [{ type = "tempo", name = "Tempo" }] : [],
    var.loki.enabled ? [{ type = "loki", name = "Loki" }] : []
  )

  namespace = var.namespace
}

module "prometheus" {
  source = "./modules/prometheus"

  count = var.prometheus.enabled ? 1 : 0

  chart_version = var.prometheus.chart_version
  configs       = var.prometheus
  namespace     = var.namespace
}

module "tempo" {
  source = "./modules/tempo"

  count = var.tempo.enabled ? 1 : 0

  chart_version = var.tempo.chart_version
  configs       = var.tempo
  namespace     = var.namespace
}

module "loki" {
  source = "./modules/loki"

  count = var.loki.enabled ? 1 : 0

  chart_version = var.loki.chart_version
  configs       = var.loki
  namespace     = var.namespace
}
