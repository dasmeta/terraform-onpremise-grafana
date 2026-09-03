locals {
  effective_metrics_generator_remote_url = coalesce(
    var.metrics_generator_remote_url,
    try(var.configs.metrics_generator.remote_url, null),
    "http://prometheus-kube-prometheus-prometheus.monitoring.svc.cluster.local:9090/api/v1/write",
  )
  effective_service_monitor_enabled = coalesce(
    var.service_monitor_enabled,
    try(var.configs.enable_service_monitor, false),
  )

  selector_owned_values = {
    tempo = {
      metricsGenerator = {
        remoteWriteUrl = local.effective_metrics_generator_remote_url
      }
    }
    serviceMonitor = {
      enabled = local.effective_service_monitor_enabled
    }
  }
}
