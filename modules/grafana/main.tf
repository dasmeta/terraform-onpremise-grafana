# Deploy Grafana
resource "helm_release" "grafana" {
  name             = "grafana"
  repository       = "https://grafana.github.io/helm-charts"
  chart            = "grafana"
  namespace        = var.namespace
  create_namespace = true
  version          = var.chart_version
  timeout          = 600

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

      request_cpu    = var.configs.resources.request.cpu
      request_memory = var.configs.resources.request.mem
      limit_cpu      = var.configs.resources.limit.cpu
      limit_memory   = var.configs.resources.limit.mem

      replicas = var.configs.replicas

      redundancy_enabled = var.configs.redundancy.enabled
      hpa_max_replicas   = var.configs.redundancy.max_replicas
      hpa_min_replicas   = var.configs.redundancy.min_replicas

      grafana_root_url            = local.grafana_root_url
      create_service_account      = var.configs.service_account.enable
      service_account_annotations = var.configs.service_account.annotations
    })
  ]

  set {
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
  create_namespace = false
  version          = var.mysql_chart_version
  timeout          = 300

  values = [jsonencode({
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
  })]
}

resource "grafana_data_source" "this" {
  for_each = local.merged_datasources

  name = each.value.name
  type = each.value.type

  json_data_encoded        = try(each.value.encoded_json, "")
  secure_json_data_encoded = try(each.value.secure_encoded_data, "")
  access_mode              = try(each.value.access_mode, "proxy")
  basic_auth_enabled       = length(try(each.value.basic_auth_username, "")) > 0
  basic_auth_username      = try(each.value.basic_auth_username, null)
  database_name            = try(each.value.database_name, null)
  is_default               = try(each.value.is_deafult, false)
  url                      = try(each.value.url, "")
  username                 = try(each.value.username, null)
  uid                      = try(each.value.uid, null)

  depends_on = [helm_release.grafana]
}
