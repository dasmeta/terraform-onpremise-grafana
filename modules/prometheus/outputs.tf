output "helm_metadata" {
  value       = helm_release.prometheus.metadata
  description = "prometheus helm release metadata"
}
