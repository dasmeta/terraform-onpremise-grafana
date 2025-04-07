module "application_dashboard" {
  source = "./modules/dashboard/"

  count = length(var.application_dashboard) > 0 ? 1 : 0

  name        = var.name
  rows        = var.application_dashboard.rows
  data_source = var.application_dashboard.data_source
  variables   = var.application_dashboard.variables

  depends_on = [module.grafana, module.prometheus]
}

module "alerts" {
  source = "./modules/alerts"

  count = var.alerts != null ? 1 : 0

  alert_interval_seconds = var.alerts.alert_interval_seconds
  disable_provenance     = var.alerts.disable_provenance
  rules                  = var.alerts.rules
  contact_points         = var.alerts.contact_points
  notifications          = var.alerts.notifications

  depends_on = [module.grafana, module.prometheus]
}

module "grafana" {
  source = "./modules/grafana"

  count = var.grafana_configs.enabled ? 1 : 0

  chart_version          = var.grafana_configs.chart_version
  grafana_admin_password = var.grafana_admin_password
  configs                = var.grafana_configs
  datasources            = var.grafana_configs.datasources

  namespace = var.namespace
}

module "prometheus" {
  source = "./modules/prometheus"

  count = var.prometheus_configs.enabled ? 1 : 0

  chart_version = var.prometheus_configs.chart_version
  configs       = var.prometheus_configs
  namespace     = var.namespace
}

module "tempo" {
  source = "./modules/tempo"

  count = var.tempo_configs.enabled ? 1 : 0

  chart_version = var.tempo_configs.chart_version
  configs       = var.tempo_configs
  region        = var.aws_region
  namespace     = var.namespace
}

module "loki" {
  source = "./modules/loki"

  count = var.loki_configs.enabled ? 1 : 0

  chart_version = var.loki_configs.chart_version
  configs       = var.loki_configs
  namespace     = var.namespace
}
