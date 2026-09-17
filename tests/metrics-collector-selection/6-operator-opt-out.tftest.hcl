mock_provider "helm" {}
mock_provider "grafana" {}

run "victoria_metrics_cluster_only_omits_operator" {
  command = plan

  module {
    source = "../../modules/victoria-metrics"
  }

  variables {
    agent_enabled                = false
    prometheus_converter_enabled = false
  }

  assert {
    condition = alltrue([
      length(helm_release.victoria_metrics_operator) == 0,
      length(helm_release.victoria_metrics_resources) == 0,
      output.operator_release == null,
      output.resources_release == null,
      length(output.resource_objects) == 0,
    ])
    error_message = "The VictoriaMetrics cluster must be deployable without the Operator, its CRDs/RBAC, or custom-resource release."
  }
}

run "prometheus_can_remote_write_to_cluster_without_operator" {
  command = plan

  module {
    source = "../.."
  }

  variables {
    metrics_collector = "prometheus"
    grafana           = { enabled = false }
    prometheus        = { enabled = true }
    victoria_metrics  = { enabled = true }
    tempo             = { enabled = false }
    loki_stack        = { enabled = false }
    alerts = {
      disk_capacity  = { enabled = false }
      rules          = []
      contact_points = null
      notifications  = null
    }
  }

  assert {
    condition = alltrue([
      output.metrics_collector_status.victoria_metrics_installed,
      !output.metrics_collector_status.victoria_metrics_operator_installed,
      !output.metrics_collector_status.victoria_metrics_agent_enabled,
      !output.metrics_collector_status.prometheus_converter_enabled,
      output.metrics_collector_status.prometheus_remote_write_enabled,
    ])
    error_message = "Prometheus must be able to remote-write to a VictoriaMetrics cluster without installing the Operator."
  }
}

run "victoria_metrics_collector_requires_operator" {
  command = plan

  module {
    source = "../.."
  }

  variables {
    metrics_collector = "victoria_metrics"
    grafana           = { enabled = false }
    prometheus        = { enabled = false }
    victoria_metrics  = { enabled = true }
    tempo             = { enabled = false }
    loki_stack        = { enabled = false }
    alerts = {
      disk_capacity  = { enabled = false }
      rules          = []
      contact_points = null
      notifications  = null
    }
  }

  expect_failures = [output.metrics_collector]
}
