resource "helm_release" "loki" {
  chart            = "loki"
  repository       = "https://grafana.github.io/helm-charts"
  name             = var.release_name
  namespace        = var.namespace
  create_namespace = true
  version          = var.chart_version
  timeout          = 600

  values = [
    templatefile("${path.module}/values/loki-values.yaml.tpl", {
      log_volume_enabled          = var.configs.loki.log_volume_enabled
      persistence_enabled         = var.configs.loki.persistence.enabled
      persistence_access_mode     = var.configs.loki.persistence.access_mode
      persistence_size            = var.configs.loki.persistence.size
      persistence_storage_class   = var.configs.loki.persistence.storage_class
      num_replicas                = var.configs.loki.replicas
      storage                     = local.loki_storage
      schema_configs              = jsonencode(var.configs.loki.schema_configs)
      create_service_account      = local.create_service_account
      service_account_name        = try(var.configs.loki.service_account.name, "loki")
      service_account_annotations = local.service_account_annotations
      request_cpu                 = var.configs.loki.resources.request.cpu
      request_mem                 = var.configs.loki.resources.request.mem
      limit_cpu                   = var.configs.loki.resources.limit.cpu
      limit_mem                   = var.configs.loki.resources.limit.mem
      retention_period            = var.configs.loki.retention_period
      }
    )
  ]
}

resource "helm_release" "promtail" {
  count = var.configs.promtail.enabled ? 1 : 0

  chart            = "promtail"
  repository       = "https://grafana.github.io/helm-charts"
  name             = "${var.release_name}-promtail"
  namespace        = var.namespace
  create_namespace = false
  version          = var.promtail_chart_version
  timeout          = 600

  values = [
    templatefile("${path.module}/values/promtail-values.tpl", {
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
  version = "1.3.2"

  name = local.s3_bucket_name

  lifecycle_rules = [
    {
      id      = "remove-all-created-objects-after-days"
      enabled = true

      expiration = {
        days = var.configs.loki.send_logs_s3.retention_days
      }
      filter = {
        object_size_greater_than = 0
      }
    }
  ]
}

module "loki_iam_eks_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.53.0"

  count = local.create_loki_role ? 1 : 0

  role_name = "loki-${var.cluster_name}-${random_string.random.result}"
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
  length  = 8
  special = false
  upper   = false
}
