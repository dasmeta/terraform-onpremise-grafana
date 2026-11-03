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
    tempo = merge({
      metricsGenerator = {
        remoteWriteUrl = local.effective_metrics_generator_remote_url
      }
      }, var.service_graph_enabled ? {
      overrides = {
        defaults = {
          metrics_generator = merge({
            processors = ["local-blocks", "service-graphs", "span-metrics"]
            }, length(var.service_graph_dimensions) == 0 ? {} : {
            processor = {
              service_graphs = {
                dimensions                  = var.service_graph_dimensions
                enable_client_server_prefix = true
              }
              span_metrics = {
                dimensions = var.service_graph_dimensions
              }
            }
          })
        }
      }
    } : {})
    serviceMonitor = {
      enabled = local.effective_service_monitor_enabled
    }
  }
}
