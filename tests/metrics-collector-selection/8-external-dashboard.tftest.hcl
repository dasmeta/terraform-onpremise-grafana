mock_provider "helm" {}
mock_provider "grafana" {}

run "external_dashboard_without_local_collectors" {
  command = plan
  module { source = "../.." }
  variables {
    grafana          = { enabled = false }
    prometheus       = { enabled = false }
    victoria_metrics = { enabled = false }
    tempo            = { enabled = false }
    loki_stack       = { enabled = false }
    alerts           = { disk_capacity = { enabled = false } }
  }
  assert {
    condition = alltrue([
      length(module.grafana) == 0,
      length(module.prometheus) == 0,
      length(module.victoria_metrics) == 0,
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
