output "datasources" {
  value = local.merged_datasources
}

output "helm_metadata" {
  value       = helm_release.grafana.metadata
  description = "grafana helm release metadata"
}

output "helm_metadata_mysql" {
  value       = try(helm_release.mysql[0].metadata, null)
  description = "mysql helm release metadata"
}
