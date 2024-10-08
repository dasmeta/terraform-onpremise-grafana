module "application_dashboard" {
  source = "./modules/dashboard/"

  count = length(var.application_dashboard) > 0 ? 1 : 0

  name        = var.name
  rows        = var.application_dashboard.rows
  data_source = var.application_dashboard.data_source
  variables   = var.application_dashboard.variables
}

module "alerts" {
  source = "./modules/alerts"

  count = var.alerts != null ? 1 : 0

  alert_interval_seconds = var.alerts.alert_interval_seconds
  disable_provenance     = var.alerts.disable_provenance
  rules                  = var.alerts.rules
  contact_points         = var.alerts.contact_points
  notifications          = var.alerts.notifications
}
