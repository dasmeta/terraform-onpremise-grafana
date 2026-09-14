mock_provider "helm" {}

run "victoria_metrics_cluster_uses_published_default_chart_version" {
  command = plan

  module {
    source = "../../modules/victoria-metrics"
  }

  assert {
    condition     = helm_release.victoria_metrics.version == "0.31.0"
    error_message = "The VictoriaMetrics child module must use the root module's published victoria-metrics-cluster chart default."
  }
}
