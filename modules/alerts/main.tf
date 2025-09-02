module "alert_rules" {
  source = "./modules/rules"

  count = var.rules != null ? 1 : 0

  folder_name            = var.folder_name
  create_folder          = var.create_folder
  group                  = var.group
  alert_interval_seconds = var.alert_interval_seconds
  disable_provenance     = var.disable_provenance
  alert_format_params    = var.alert_format_params
  alert_rules            = var.rules
}

module "contact_points" {
  source = "./modules/contact-points"

  count = var.contact_points != null ? 1 : 0

  disable_provenance      = var.disable_provenance
  enable_message_template = var.enable_message_template
  slack_endpoints         = var.contact_points.slack
  opsgenie_endpoints      = var.contact_points.opsgenie
  teams_endpoints         = var.contact_points.teams
  webhook_endpoints       = var.contact_points.webhook
}

module "notifications" {
  source = "./modules/notifications"

  count = var.notifications != null ? 1 : 0

  disable_provenance = var.disable_provenance
  notifications      = var.notifications

  depends_on = [module.contact_points]
}
