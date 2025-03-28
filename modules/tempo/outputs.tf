output "tempo_url" {
  description = "Internal Tempo service URL"
  value       = "http://tempo.${var.namespace}.svc.cluster.local:3100"
}
