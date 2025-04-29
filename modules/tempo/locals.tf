locals {
  eks_oidc_provider_arn       = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${replace(data.aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")}"
  create_tempo_role           = var.configs.storage_backend == "s3" && var.configs.tempo_role_arn == ""
  tempo_role                  = local.create_tempo_role ? module.tempo_iam_eks_role[0].iam_role_arn : (var.configs.storage_backend == "s3" ? var.configs.tempo_role_arn : "")
  service_account_annotations = merge(var.configs.service_account.annotations, { "eks.amazonaws.com/role-arn" = local.tempo_role })
}
