
resource "grafana_folder" "rules_folders" {
  for_each = var.create_folder ? toset(concat([
    for rule in var.rules :
    rule.folder_name != null ? rule.folder_name : var.folder_name
    if rule.folder_name != null || var.folder_name != null
  ], var.folder_name != null ? [var.folder_name] : [])) : toset([])

  title = each.value
}

module "alert_rules" {
  source = "./modules/rules"

  count = var.rules != null ? 1 : 0

  folder_name            = var.folder_name
  group                  = var.group
  alert_interval_seconds = var.alert_interval_seconds
  disable_provenance     = var.disable_provenance
  annotations            = var.annotations
  labels                 = var.labels
  alert_rules            = var.rules
  folder_name_uids       = length(var.folder_name_uids) > 0 ? var.folder_name_uids : (var.create_folder ? { for name, folder in grafana_folder.rules_folders : name => folder.uid } : {})
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
