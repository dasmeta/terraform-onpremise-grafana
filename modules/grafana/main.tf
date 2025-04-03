# Deploy Grafana
resource "helm_release" "grafana" {
  name             = "grafana"
  repository       = "https://grafana.github.io/helm-charts"
  chart            = "grafana"
  namespace        = var.namespace
  create_namespace = true
  timeout          = 600
  version          = var.chart_version

  values = [
    templatefile("${path.module}/values/grafana-values.yaml.tpl", {
      enabled_persistence = var.configs.persistence.enabled
      persistence_type    = var.configs.persistence.type
      persistence_size    = var.configs.persistence.size

      ingress_annotations = var.configs.ingress_configs.annotations
      ingress_hosts       = var.configs.ingress_configs.hosts
      ingress_path        = var.configs.ingress_configs.path
      ingress_path_type   = var.configs.ingress_configs.path_type

      # prometheus_enable   = var.prometheus_datasource
      # prometheus_url      = var.configs.prometheus_url
      # cloudwatch_enable   = var.cloudwatch_datasource
      # cloudwatch_role_arn = module.grafana_cloudwatch_role[0].arn
      # aws_region          = var.aws_region

      request_cpu    = var.configs.resources.request.cpu
      request_memory = var.configs.resources.request.mem
      limit_cpu      = var.configs.resources.limit.cpu
      limit_memory   = var.configs.resources.limit.mem

      replicas = var.configs.replicas
    })
  ]

  set {
    name  = "adminPassword"
    value = var.grafana_admin_password
  }
}

resource "grafana_data_source" "this" {
  for_each = local.data_sources

  name = each.value.name
  type = each.value.type

  json_data_encoded        = try(each.value.encoded_json, "")
  secure_json_data_encoded = try(each.value.secure_encoded_data, "")
  access_mode              = try(each.value.access_mode)
  basic_auth_enabled       = length(try(each.value.basic_auth_username, "")) > 0
  basic_auth_username      = try(each.value.basic_auth_username, null)
  database_name            = try(each.value.database_name, null)
  is_default               = try(each.value.is_deafult, false)
  url                      = try(each.value.url)
  username                 = try(each.value.username, null)

  depends_on = [helm_release.grafana]
}


module "grafana_cloudwatch_role" {
  count   = var.cloudwatch_datasource.enabled ? 1 : 0
  source  = "dasmeta/iam/aws//modules/role"
  version = "1.3.0"

  name   = "grafana-cloudwatch-role"
  policy = local.cloudwatch_policies
  trust_relationship = [
    {
      principals = {
        type        = "Service"
        identifiers = ["eks.amazonaws.com", ]
      },
      actions = ["sts:AssumeRole"]
    }
  ]
}
