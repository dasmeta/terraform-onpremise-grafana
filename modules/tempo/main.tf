resource "helm_release" "tempo" {
  name             = "tempo"
  repository       = "https://grafana.github.io/helm-charts"
  chart            = "tempo"
  version          = var.chart_version
  namespace        = var.namespace
  create_namespace = true

  values = [
    templatefile("${path.module}/values/tempo-values.yaml.tpl", {
      storage_backend = var.configs.storage_backend
      bucket_name     = module.tempo_bucket.s3_bucket_id
      region          = data.aws_region.current.name

      persistence_enabled = var.configs.persistence.enabled
      persistence_size    = var.configs.persistence.size
      persistence_class   = var.configs.persistence.storage_class

      metris_generator_enabled     = var.configs.metrics_generator.enabled
      metrics_generator_remote_url = var.configs.metrics_generator.remote_url

      enable_service_monitor = var.configs.enable_service_monitor

      service_account_name        = var.configs.service_account.name
      service_account_annotations = local.service_account_annotations
    })
  ]
  depends_on = [module.tempo_bucket]
}

module "tempo_bucket" {
  source  = "dasmeta/s3/aws"
  version = "1.3.1"

  name = var.configs.bucket_name
}

module "tempo_iam_eks_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.53.0"

  count = local.create_tempo_role ? 1 : 0

  role_name = "${var.configs.tempo_role_name}-role"
  role_policy_arns = {
    policy = resource.aws_iam_policy.tempo_s3_access[0].arn
  }

  oidc_providers = {
    one = {
      provider_arn               = local.eks_oidc_provider_arn
      namespace_service_accounts = ["${var.namespace}:${var.configs.service_account.name}"]
    }
  }
}

resource "aws_iam_policy" "tempo_s3_access" {
  count = local.create_tempo_role ? 1 : 0
  name  = "${var.configs.tempo_role_name}-policy"
  path  = "/"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["s3:ListBucket"],
        Resource = "arn:aws:s3:::${var.configs.bucket_name}"
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
        Resource = "arn:aws:s3:::${var.configs.bucket_name}/*"
      }
    ]
  })

}
