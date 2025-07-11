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

      grafana_iam_role_arn = try(module.grafana_cloudwatch_role[0].arn, "")
    })
  ]

  set {
    name  = "adminPassword"
    value = var.grafana_admin_password
  }

  depends_on = [kubernetes_persistent_volume_claim.grafana_efs, module.grafana_cloudwatch_role]
}

resource "helm_release" "mysql" {
  count = var.configs.database.enabled && var.configs.database.create ? 1 : 0

  name             = var.mysql_release_name
  repository       = "oci://registry-1.docker.io/bitnamicharts"
  chart            = "mysql"
  namespace        = var.namespace
  create_namespace = false
  version          = var.mysql_chart_version
  timeout          = 600

  values = [jsonencode({
    persistence = var.configs.database.persistence
    auth = {
      username     = local.database.username
      database     = local.database.name,
      password     = local.database.password
      rootPassword = local.database.root_password
    }
    primary = {
      extraFlags = var.configs.database.extra_flags
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


module "grafana_cloudwatch_role" {
  count = anytrue([
    for ds in local.merged_datasources : ds.type == "cloudwatch"
  ]) ? 1 : 0
  source  = "dasmeta/iam/aws//modules/role"
  version = "1.3.0"

  name   = "grafana-cloudwatch-role"
  policy = local.cloudwatch_policies
  trust_relationship = [
    {
      principals = {
        type        = "Federated"
        identifiers = [local.eks_oidc_provider_arn]
      }
      conditions = [{
        type  = "StringEquals"
        key   = "${replace(data.aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")}:sub"
        value = ["system:serviceaccount:${var.namespace}:grafana-service-account"]
      }]
      actions = ["sts:AssumeRoleWithWebIdentity"]
    }
  ]
}


resource "kubernetes_persistent_volume_claim" "grafana_efs" {
  count = var.configs.redundancy.enabled && var.configs.persistence.enabled ? 1 : 0
  metadata {
    name      = "grafana-shared-pvc"
    namespace = var.namespace
  }

  spec {
    access_modes = ["ReadWriteMany"]

    resources {
      requests = {
        storage = var.configs.persistence.size
      }
    }

    storage_class_name = var.configs.redundancy.redundancy_storage_class
  }

}
