mock_provider "helm" {}

run "service_graph_processors_have_no_custom_dimensions_by_default" {
  command = plan

  module {
    source = "./modules/tempo"
  }

  variables {
    configs                      = {}
    metrics_generator_remote_url = "http://vminsert.monitoring.svc.cluster.local:8480/insert/0/prometheus/api/v1/write"
    service_monitor_enabled      = false
    service_graph_enabled        = true
  }

  assert {
    condition = try(alltrue([
      yamldecode(helm_release.tempo.values[2]).tempo.overrides.defaults.metrics_generator.processors == ["local-blocks", "service-graphs", "span-metrics"],
      !contains(keys(yamldecode(helm_release.tempo.values[2]).tempo.overrides.defaults.metrics_generator), "processor"),
    ]), false)
    error_message = "VictoriaMetrics-backed Tempo must preserve local-blocks and enable both topology processors without adding dimensions by default."
  }
}

run "service_graph_dimensions_are_applied_to_both_processors" {
  command = plan

  module {
    source = "./modules/tempo"
  }

  variables {
    configs                      = {}
    metrics_generator_remote_url = "http://vminsert.monitoring.svc.cluster.local:8480/insert/0/prometheus/api/v1/write"
    service_monitor_enabled      = false
    service_graph_enabled        = true
    service_graph_dimensions     = ["deployment.environment.name"]
  }

  assert {
    condition = try(alltrue([
      yamldecode(helm_release.tempo.values[2]).tempo.overrides.defaults.metrics_generator.processor.service_graphs.dimensions == ["deployment.environment.name"],
      yamldecode(helm_release.tempo.values[2]).tempo.overrides.defaults.metrics_generator.processor.service_graphs.enable_client_server_prefix,
      yamldecode(helm_release.tempo.values[2]).tempo.overrides.defaults.metrics_generator.processor.span_metrics.dimensions == ["deployment.environment.name"],
      !contains(keys(yamldecode(helm_release.tempo.values[2]).tempo.overrides.defaults.metrics_generator.processor.span_metrics), "enable_client_server_prefix"),
    ]), false)
    error_message = "Configured service-graph dimensions must apply consistently to service-graphs and span-metrics."
  }
}
