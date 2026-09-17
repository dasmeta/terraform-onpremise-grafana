output "helm_metadata_loki" {
  value       = helm_release.loki.metadata
  description = "loki helm release metadata"
}

output "helm_metadata_promtail" {
  value       = try(helm_release.promtail[0].metadata, null)
  description = "promtail helm release metadata"
}

output "query_url" {
  value       = local.loki_query_url
  description = "In-cluster Loki query URL for Grafana datasource (mode-aware)"
}

output "push_url" {
  value       = local.loki_push_url
  description = "In-cluster Loki push URL for Promtail clients (mode-aware)"
}

output "deployment_mode" {
  value       = local.loki_deployment_mode
  description = "Resolved Loki deployment mode"
}

output "release" {
  value = {
    name      = local.loki_release_name
    namespace = var.namespace
    chart     = "loki"
    version   = var.configs.loki.chart_version
  }
  description = "Non-sensitive identity of the Loki release used for native scrape discovery."
}

output "prometheus_monitor_enabled" {
  value       = local.effective_prometheus_monitor_enabled
  description = "Resolved Loki Prometheus ServiceMonitor state."
}
