output "datasources" {
  value = local.merged_datasources
}

output "oidc_provider" {
  value = local.eks_oidc_provider_arn
}
