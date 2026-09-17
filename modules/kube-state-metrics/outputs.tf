output "helm_metadata" {
  value       = helm_release.kube_state_metrics.metadata
  description = "kube-state-metrics Helm release metadata."
}

output "service_target" {
  value       = local.service_target
  description = "In-cluster kube-state-metrics scrape target."
}
