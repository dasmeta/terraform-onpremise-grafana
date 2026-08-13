output "helm_metadata" {
  value       = helm_release.victoria_metrics.metadata
  description = "victoria metrics helm release metadata"
}
