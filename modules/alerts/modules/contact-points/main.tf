# Slack Integration
resource "grafana_contact_point" "slack_contact_point" {
  for_each = { for cp in var.slack_endpoints : cp.name => cp }

  name               = each.key
  disable_provenance = var.disable_provenance

  slack {
    endpoint_url            = each.value.webhook_url
    icon_emoji              = each.value.icon_emoji
    icon_url                = each.value.icon_url
    recipient               = each.value.webhook_url != null ? each.value.recipient : null
    text                    = each.value.text
    title                   = each.value.title
    token                   = each.value.webhook_url != null ? each.value.token : null
    url                     = each.value.webhook_url
    username                = each.value.username
    disable_resolve_message = each.value.disable_resolve_message
  }
}

# OpsGenie Integration
resource "grafana_contact_point" "opsgenie_contact_point" {
  for_each = { for cp in var.opsgenie_endpoints : cp.name => cp }

  name               = each.key
  disable_provenance = var.disable_provenance

  opsgenie {
    api_key                 = each.value.api_key
    auto_close              = each.value.auto_close
    message                 = each.value.message
    url                     = each.value.api_url
    disable_resolve_message = each.value.disable_resolve_message
  }
}

# MS Teams Integration
resource "grafana_contact_point" "teams_contact_point" {
  for_each = { for cp in var.teams_endpoints : cp.name => cp }

  name               = each.key
  disable_provenance = var.disable_provenance

  teams {
    title                   = each.value.title
    url                     = each.value.url
    message                 = each.value.message
    section_title           = each.value.section_title
    disable_resolve_message = each.value.disable_resolve_message
  }
}


# Webhook endpoints Integration
resource "grafana_contact_point" "webhook_contact_point" {
  for_each = { for cp in var.webhook_endpoints : cp.name => cp }

  name               = each.key
  disable_provenance = var.disable_provenance

  webhook {
    url                       = each.value.url
    authorization_credentials = each.value.authorization_credentials
    authorization_scheme      = each.value.authorization_scheme
    basic_auth_password       = each.value.basic_auth_password
    basic_auth_user           = each.value.basic_auth_user
    disable_resolve_message   = each.value.disable_resolve_message
    settings                  = each.value.settings
  }
}
