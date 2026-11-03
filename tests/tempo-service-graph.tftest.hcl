mock_provider "helm" {}
mock_provider "grafana" {}
mock_provider "random" {}
mock_provider "time" {}

run "tempo_with_victoria_metrics_uses_the_existing_datasource" {
  command = apply

  variables {
    grafana_admin_password = "test-password"
    metrics_collector      = "victoria_metrics"
    grafana                = { enabled = true }
    tempo                  = { enabled = true }
    victoria_metrics       = { enabled = true, operator = { enabled = true } }
  }

  assert {
    condition = try(alltrue([
      jsondecode(output.grafana.datasources.Tempo.encoded_json).tracesToMetrics.datasourceUid == "victoriametrics",
      jsondecode(output.grafana.datasources.Tempo.encoded_json).serviceMap.datasourceUid == "victoriametrics",
      jsondecode(output.grafana.datasources.Tempo.encoded_json).nodeGraph.enabled,
    ]), false)
    error_message = "The built-in Tempo datasource must use VictoriaMetrics for trace metrics and topology views."
  }
}

run "tempo_without_victoria_metrics_preserves_existing_datasource_behavior" {
  command = apply

  variables {
    grafana_admin_password = "test-password"
    metrics_collector      = "prometheus"
    grafana                = { enabled = true }
    tempo                  = { enabled = true }
    victoria_metrics       = { enabled = false }
  }

  assert {
    condition = try(alltrue([
      jsondecode(output.grafana.datasources.Tempo.encoded_json).tracesToMetrics.datasourceUid == "prometheus",
      !contains(keys(jsondecode(output.grafana.datasources.Tempo.encoded_json)), "serviceMap"),
      !contains(keys(jsondecode(output.grafana.datasources.Tempo.encoded_json)), "nodeGraph"),
    ]), false)
    error_message = "Tempo must not reference VictoriaMetrics service-map fields when VictoriaMetrics is disabled."
  }
}
