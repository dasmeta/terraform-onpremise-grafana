output "helm_metadata_loki" {
  value       = helm_release.loki.metadata
  description = "loki helm release metadata"
}

output "helm_metadata_promtail" {
  value       = try(helm_release.promtail[0].metadata, null)
  description = "promtail helm release metadata"
}
