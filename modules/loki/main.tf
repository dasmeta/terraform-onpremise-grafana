resource "helm_release" "loki" {
  chart            = "loki-stack"
  repository       = "https://grafana.github.io/helm-charts"
  name             = var.release_name
  namespace        = var.namespace
  create_namespace = true
  version          = var.chart_version
  timeout          = 600

  values = [
    templatefile("${path.module}/values/loki-values.yaml.tpl", {
      loki_url                    = var.configs.loki.url == "" ? "http://${var.release_name}:3100" : var.configs.loki.url
      log_volume_enabled          = var.configs.loki.log_volume_enabled
      persistence_enabled         = var.configs.loki.persistence.enabled
      persistence_access_mode     = var.configs.loki.persistence.access_mode
      persistence_size            = var.configs.loki.persistence.size
      persistence_storage_class   = var.configs.loki.persistence.storage_class
      redundency_enabled          = local.redundency_enabled
      num_replicas                = var.configs.loki.replicas
      storage_configs             = local.loki_storage_configs
      schema_configs_yaml         = local.schema_configs_yaml
      schema_configs_raw          = local.schema_configs
      create_service_account      = local.create_service_account
      service_account_name        = try(var.configs.loki.service_account.name, "loki")
      service_account_annotations = local.service_account_annotations
      request_cpu                 = var.configs.loki.resources.request.cpu
      request_mem                 = var.configs.loki.resources.request.mem
      limit_cpu                   = var.configs.loki.resources.limit.cpu
      limit_mem                   = var.configs.loki.resources.limit.mem
      retention_period            = var.configs.loki.retention_period

      promtail_enabled                  = var.configs.promtail.enabled
      promtail_log_level                = var.configs.promtail.log_level
      log_format                        = var.configs.promtail.log_format
      promtail_extra_scrape_configs     = local.extra_scrape_configs_yaml
      promtail_extra_label_configs_yaml = local.extra_relabel_configs_yaml
      promtail_extra_label_configs_raw  = local.extra_relabel_configs
      promtail_clients                  = try(var.configs.promtails.clients, ["http://${var.release_name}:3100/loki/api/v1/push"])
      promtail_server_port              = var.configs.promtail.server_port
      enabled_fluentbit                 = var.configs.fluentbit_enabled
      enabled_test_pod                  = var.configs.enable_test_pod
      }
    )
  ]
}


module "loki_bucket" {
  source  = "dasmeta/s3/aws"
  version = "1.3.1"

  name = local.s3_bucket_name
}

module "loki_iam_eks_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.53.0"

  count = local.create_loki_role ? 1 : 0

  role_name = "loki-role"
  role_policy_arns = {
    policy = resource.aws_iam_policy.loki_s3_access[0].arn
  }

  oidc_providers = {
    one = {
      provider_arn               = local.eks_oidc_provider_arn
      namespace_service_accounts = ["${var.namespace}:${var.configs.loki.service_account.name}"]
    }
  }
}

resource "aws_iam_policy" "loki_s3_access" {
  count = local.create_loki_role ? 1 : 0
  name  = "loki-policy"
  path  = "/"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["s3:ListBucket"],
        Resource = "arn:aws:s3:::${local.s3_bucket_name}"
      },
      {
        Effect = "Allow",
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListObjects",
          "s3:DeleteObject",
          "s3:GetObjectTagging",
          "s3:PutObjectTagging"
        ],
        Resource = "arn:aws:s3:::${local.s3_bucket_name}/*"
      }
    ]
  })

}

resource "random_string" "random" {
  length  = 16
  special = false
  upper   = false
}
