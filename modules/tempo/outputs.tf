output "tempo_url" {
  description = "Internal Tempo service URL"
  value       = "http://tempo.${var.namespace}.svc.cluster.local:3100"
}

output "helm_metadata" {
  value       = helm_release.tempo.metadata
  description = "tempo helm release metadata"
}
