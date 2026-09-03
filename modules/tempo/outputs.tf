output "tempo_url" {
  description = "Internal Tempo service URL"
  value       = "http://tempo.${var.namespace}.svc.cluster.local:3100"
}

output "helm_metadata" {
  value       = helm_release.tempo.metadata
  description = "tempo helm release metadata"
}

output "service_monitor_enabled" {
  value       = local.effective_service_monitor_enabled
  description = "Resolved Tempo Prometheus ServiceMonitor state."
}
