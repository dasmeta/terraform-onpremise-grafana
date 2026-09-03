output "helm_metadata" {
  value       = helm_release.node_exporter.metadata
  description = "node-exporter Helm release metadata."
}

output "release" {
  value = {
    name      = var.release_name
    namespace = var.namespace
    chart     = "prometheus-node-exporter"
    version   = var.chart_version
  }
  description = "Non-sensitive identity of the independent node-exporter release."
}

output "service_target" {
  value       = local.service_target
  description = "In-cluster node-exporter scrape target."
}

output "prometheus_monitor_enabled" {
  value       = var.prometheus_monitor_enabled
  description = "Resolved Prometheus ServiceMonitor activation state."
}
