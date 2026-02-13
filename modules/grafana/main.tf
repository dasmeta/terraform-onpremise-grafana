# Deploy Grafana
resource "helm_release" "grafana" {
  name             = var.release_name
  repository       = "https://grafana.github.io/helm-charts"
  chart            = "grafana"
  namespace        = var.namespace
  create_namespace = var.create_namespace
  version          = var.chart_version
  timeout          = 300

  values = [
    templatefile("${path.module}/values/grafana-values.yaml.tpl", {
      database = var.configs.database.enabled ? jsonencode({ # if we enable/set database, no need for enabling persistence
        host     = local.database.host
        user     = local.database.username
        password = local.database.password
        name     = local.database.name
        type     = local.database.type
        }
      ) : null
      enabled_persistence       = var.configs.persistence.enabled
      persistence_type          = var.configs.persistence.type
      persistence_size          = var.configs.persistence.size
      persistence_storage_class = var.configs.persistence.storage_class
      pvc_name                  = var.configs.redundancy.enabled && var.configs.persistence.enabled ? "grafana-shared-pvc" : ""

      ingress_annotations = local.ingress_annotations
      ingress_hosts       = var.configs.ingress.hosts
      ingress_path        = var.configs.ingress.path
      ingress_path_type   = var.configs.ingress.path_type
      tls_secrets         = local.ingress_tls
      ingress_class_name  = var.configs.ingress.type

      request_cpu    = var.configs.resources.requests.cpu
      request_memory = var.configs.resources.requests.memory
      limit_cpu      = var.configs.resources.limits.cpu
      limit_memory   = var.configs.resources.limits.memory

      replicas = var.configs.replicas

      redundancy_enabled = var.configs.redundancy.enabled
      hpa_max_replicas   = var.configs.redundancy.max_replicas
      hpa_min_replicas   = var.configs.redundancy.min_replicas

      grafana_root_url            = local.grafana_root_url
      create_service_account      = var.configs.service_account.enable
      service_account_name        = var.configs.service_account.name
      service_account_annotations = var.configs.service_account.annotations
    }),
    jsonencode(var.extra_configs)
  ]

  set_sensitive {
    name  = "adminPassword"
    value = var.grafana_admin_password
  }

  depends_on = [helm_release.mysql]
}

resource "helm_release" "mysql" {
  count = var.configs.database.enabled && var.configs.database.create ? 1 : 0

  name             = var.mysql_release_name
  repository       = "oci://registry-1.docker.io/bitnamicharts"
  chart            = "mysql"
  namespace        = var.namespace
  create_namespace = var.create_namespace
  version          = var.mysql_chart_version
  timeout          = 300

  values = [
    jsonencode(local.switchBitnamiChartRegistry),
    jsonencode(
      {
        auth = {
          username     = local.database.username
          database     = local.database.name,
          password     = local.database.password
          rootPassword = local.database.root_password
        }
        primary = {
          extraFlags = var.configs.database.extra_flags
          persistence = {
            enabled      = var.configs.database.persistence.enabled
            size         = var.configs.database.persistence.size
            storageClass = var.configs.database.persistence.storage_class
          }
        }
      }
    ),
    jsonencode(var.mysql_extra_configs)
  ]
}

resource "grafana_data_source" "this" {
  for_each = nonsensitive(local.merged_datasources)

  name = each.value.name
  type = each.value.type

  json_data_encoded        = try(each.value.encoded_json, "")
  secure_json_data_encoded = try(each.value.secure_encoded_data, "")
  access_mode              = try(each.value.access_mode, "proxy")
  basic_auth_enabled       = length(try(each.value.basic_auth_username, "")) > 0
  basic_auth_username      = try(each.value.basic_auth_username, null)
  database_name            = try(each.value.database_name, null)
  is_default               = try(each.value.is_default, false)
  url                      = try(each.value.url, "")
  username                 = try(each.value.username, null)
  uid                      = try(each.value.uid, null)

  depends_on = [time_sleep.wait_for_grafana]
}

# Wait for Grafana to be fully up before applying datasources and SSO settings
resource "time_sleep" "wait_for_grafana" {
  depends_on = [helm_release.grafana]

  create_duration = var.grafana_wait_duration
}

resource "grafana_sso_settings" "this" {
  for_each = toset(nonsensitive(keys(var.sso_settings)))

  provider_name = each.key

  dynamic "oauth2_settings" {
    for_each = var.sso_settings[each.key].oauth2_settings != null ? [var.sso_settings[each.key].oauth2_settings] : []
    content {
      name          = oauth2_settings.value.name
      client_id     = oauth2_settings.value.client_id
      client_secret = oauth2_settings.value.client_secret
      # For built-in providers (gitlab, github, google, azuread, okta), URLs are auto-configured by Grafana
      # Only set these for generic_oauth or self-hosted instances
      auth_url                   = contains(["gitlab", "github", "google", "azuread", "okta"], each.key) ? null : try(oauth2_settings.value.auth_url, null)
      token_url                  = contains(["gitlab", "github", "google", "azuread", "okta"], each.key) ? null : try(oauth2_settings.value.token_url, null)
      api_url                    = contains(["gitlab", "github", "google", "azuread", "okta"], each.key) ? null : try(oauth2_settings.value.api_url, null)
      allow_sign_up              = try(oauth2_settings.value.allow_sign_up, true)
      auto_login                 = try(oauth2_settings.value.auto_login, false)
      scopes                     = try(oauth2_settings.value.scopes, null)
      allowed_groups             = try(oauth2_settings.value.allowed_groups, null)
      allowed_domains            = try(oauth2_settings.value.allowed_domains, null)
      role_attribute_path        = try(oauth2_settings.value.role_attribute_path, null)
      role_attribute_strict      = try(oauth2_settings.value.role_attribute_strict, null)
      allow_assign_grafana_admin = try(oauth2_settings.value.allow_assign_grafana_admin, null)
      skip_org_role_sync         = try(oauth2_settings.value.skip_org_role_sync, null)
    }
  }

  dynamic "saml_settings" {
    for_each = var.sso_settings[each.key].saml_settings != null ? [var.sso_settings[each.key].saml_settings] : []
    content {
      name             = saml_settings.value.name
      idp_metadata_url = try(saml_settings.value.idp_metadata_url, null)
      allow_sign_up    = try(saml_settings.value.allow_sign_up, true)
      auto_login       = try(saml_settings.value.auto_login, false)
    }
  }

  # Note: LDAP support structure may vary by Grafana provider version
  # LDAP is in preview (Grafana v11.3+) and the exact structure should be verified
  # against the provider documentation
  dynamic "ldap_settings" {
    for_each = var.sso_settings[each.key].ldap_settings != null ? [var.sso_settings[each.key].ldap_settings] : []
    content {
      allow_sign_up = try(ldap_settings.value.allow_sign_up, true)
      dynamic "config" {
        for_each = try(ldap_settings.value.config != null, false) ? [ldap_settings.value.config] : []
        content {
          dynamic "servers" {
            for_each = config.value.servers
            content {
              host            = servers.value.host
              port            = try(servers.value.port, 389)
              search_base_dns = servers.value.search_base_dns
              search_filter   = servers.value.search_filter
            }
          }
        }
      }
    }
  }

  depends_on = [time_sleep.wait_for_grafana]
}
