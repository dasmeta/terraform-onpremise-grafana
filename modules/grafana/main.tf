# Deploy Grafana
resource "helm_release" "grafana" {
  name             = "grafana"
  repository       = "https://grafana.github.io/helm-charts"
  chart            = "grafana"
  namespace        = var.namespace
  create_namespace = true
  timeout          = 600
  version          = "8.5.6"

  values = [
    templatefile("${path.module}/values/grafana-values.yaml.tpl", {
      enabled_persistence = var.configs.persistence.enabled
      persistence_type    = var.configs.persistence.type
      persistence_size    = var.configs.persistence.size

      ingress_annotations = var.configs.ingress_configs.annotations
      ingress_hosts       = var.configs.ingress_configs.hosts
      ingress_path        = var.configs.ingress_configs.path
      ingress_path_type   = var.configs.ingress_configs.path_type

      prometheus_enable   = var.prometheus_datasource
      prometheus_url      = var.configs.prometheus_url
      cloudwatch_enable   = var.cloudwatch_datasource
      cloudwatch_role_arn = module.grafana_cloudwatch_role[0].arn
      aws_region          = var.aws_region

      request_cpu    = var.configs.resources.request.cpu
      request_memory = var.configs.resources.request.mem
      limit_cpu      = var.configs.resources.limit.cpu
      limit_memory   = var.configs.resources.limit.mem

      replicas  = var.configs.replicas
      image_tag = var.configs.image_tag
    })
  ]

  set {
    name  = "adminPassword"
    value = var.grafana_admin_password
  }
}


module "grafana_cloudwatch_role" {
  count   = var.cloudwatch_datasource ? 1 : 0
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
