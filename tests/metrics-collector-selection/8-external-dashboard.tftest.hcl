mock_provider "helm" {}
mock_provider "grafana" {}

run "external_dashboard_without_local_collectors" {
  command = plan
  module { source = "../.." }
  variables {
    grafana            = { enabled = false }
    prometheus         = { enabled = false }
    victoria_metrics   = { enabled = false }
    kube_state_metrics = { enabled = false }
    node_exporter      = { enabled = false }
    tempo              = { enabled = false }
    loki_stack         = { enabled = false }
    alerts             = { disk_capacity = { enabled = false } }
    application_dashboard = [{
      name        = "external-dashboard"
      data_source = { uid = "external-metrics", type = "prometheus" }
      rows        = [{ type = "block/service", name = "example", namespace = "example", alerts = { enabled = false } }]
    }]
  }
  assert {
    condition = alltrue([
      length(module.grafana) == 0,
      length(module.prometheus) == 0,
      length(module.victoria_metrics) == 0,
      length(module.kube_state_metrics) == 0,
      length(module.node_exporter) == 0,
      strcontains(jsonencode(module.application_dashboard["external-dashboard"].widget_result), "external-metrics"),
    ])
    error_message = "External dashboard mode must not create Grafana or metrics collectors."
  }
}

run "grafana_requires_selected_collector" {
  command = plan
  module { source = "../.." }
  variables {
    grafana_admin_password = "test-password"
    grafana                = { enabled = true }
    prometheus             = { enabled = false }
    victoria_metrics       = { enabled = false }
    tempo                  = { enabled = false }
    loki_stack             = { enabled = false }
    alerts                 = { disk_capacity = { enabled = false } }
  }
  expect_failures = [output.metrics_collector]
}

run "selected_prometheus_requires_install_when_other_collector_enabled" {
  command = plan
  module { source = "../.." }
  variables {
    grafana          = { enabled = false }
    prometheus       = { enabled = false }
    victoria_metrics = { enabled = true }
    tempo            = { enabled = false }
    loki_stack       = { enabled = false }
    alerts           = { disk_capacity = { enabled = false } }
  }
  expect_failures = [output.metrics_collector]
}
