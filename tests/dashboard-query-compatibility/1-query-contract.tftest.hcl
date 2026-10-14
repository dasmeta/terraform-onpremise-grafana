mock_provider "grafana" {}
mock_provider "random" {}

run "legacy_mode_renders_the_recorded_dashboard_query_contract" {
  command = plan

  module {
    source = "../../modules/dashboard"
  }

  variables {
    name             = "legacy-query-contract"
    folder_name      = "dashboards"
    folder_name_uids = { dashboards = "dashboard-folder" }
    defaults = {
      period = "5m"
      query_compatibility = {
        legacy_dashboard_queries = true
      }
    }
    rows = [
      [
        { type = "container/memory", container = "service", namespace = "prod" },
        { type = "container/network", container = "service", namespace = "prod" },
        { type = "container/replicas", container = "service", namespace = "prod" },
      ],
      [
        { type = "ingress/memory", pod = "gateway", namespace = "prod" },
        { type = "container/network-traffic", pod = "gateway", namespace = "prod" },
        { type = "container/network-error", pod = "gateway", namespace = "prod" },
      ],
      [
        { type = "pod/cpu", pod = "worker", namespace = "prod" },
        { type = "pod/memory", pod = "worker", namespace = "prod" },
        { type = "pod/restarts", pod = "worker", namespace = "prod" },
      ],
    ]
  }

  assert {
    condition = alltrue([
      contains(flatten([for panel in output.widget_result : [for target in panel.targets : target.expr]]), "avg(container_memory_usage_bytes{container=\"service\", namespace=\"prod\"})"),
      contains(flatten([for panel in output.widget_result : [for target in panel.targets : target.expr]]), "avg(container_memory_usage_bytes{pod=~'(.+-)?gateway(-[^-]+)?-[^-]+$', namespace=\"prod\"})"),
      contains(flatten([for panel in output.widget_result : [for target in panel.targets : target.expr]]), "avg(rate(container_memory_usage_bytes{pod=~\"worker-[^-]+-[^-]+$\", namespace=\"prod\"}[5m]))"),
      contains(flatten([for panel in output.widget_result : [for target in panel.targets : target.expr]]), "sum(rate(container_network_receive_bytes_total{namespace=\"prod\", pod=~\"^service-[^-]+-[^-]+$\"}[5m]))"),
      contains(flatten([for panel in output.widget_result : [for target in panel.targets : target.expr]]), "sum(rate(container_network_receive_bytes_total{namespace=\"prod\", pod=~\"^gateway(-[^-]+)?-[^-]+$\"}[5m]))"),
      contains(flatten([for panel in output.widget_result : [for target in panel.targets : target.expr]]), "sum(rate(container_network_transmit_errors_total{namespace=\"prod\", pod=~\"^gateway(-[^-]+)?-[^-]+$\"}[5m]))"),
      contains(flatten([for panel in output.widget_result : [for target in panel.targets : target.expr]]), "sum(kube_pod_status_phase{namespace=\"prod\", pod=~\"^service-[^-]+-[^-]+$\"})"),
      contains(flatten([for panel in output.widget_result : [for target in panel.targets : target.expr]]), "avg(rate(container_cpu_usage_seconds_total{pod=~\"worker-[^-]+-[^-]+$\", namespace=\"prod\"}[5m]))"),
      contains(flatten([for panel in output.widget_result : [for target in panel.targets : target.expr]]), "sum(rate(kube_pod_container_status_restarts_total{pod=~\"^worker-[^-]+-[^-]+$\"}[5m]))"),
    ])
    error_message = "legacy mode must render every affected dashboard query exactly as released in v1.28.2"
  }
}

run "omitted_compatibility_keeps_the_modern_dashboard_query_contract" {
  command = plan

  module {
    source = "../../modules/dashboard"
  }

  variables {
    name             = "modern-query-contract"
    folder_name      = "dashboards"
    folder_name_uids = { dashboards = "dashboard-folder" }
    defaults         = { period = "5m" }
    rows = [
      [
        { type = "container/memory", container = "service", namespace = "prod" },
        { type = "container/network", container = "service", namespace = "prod" },
        { type = "container/replicas", container = "service", namespace = "prod" },
      ],
      [
        { type = "ingress/memory", pod = "gateway", namespace = "prod" },
        { type = "container/network-traffic", pod = "gateway", namespace = "prod" },
        { type = "container/network-error", pod = "gateway", namespace = "prod" },
      ],
      [
        { type = "pod/cpu", pod = "worker", namespace = "prod" },
        { type = "pod/memory", pod = "worker", namespace = "prod" },
        { type = "pod/restarts", pod = "worker", namespace = "prod" },
      ],
    ]
  }

  assert {
    condition = alltrue([
      contains(flatten([for panel in output.widget_result : [for target in panel.targets : target.expr]]), "avg(container_memory_working_set_bytes{container=\"service\", namespace=\"prod\"})"),
      contains(flatten([for panel in output.widget_result : [for target in panel.targets : target.expr]]), "avg(container_memory_working_set_bytes{pod=~'(.+-)?gateway(-[^-]+)?-[^-]+$', namespace=\"prod\"})"),
      contains(flatten([for panel in output.widget_result : [for target in panel.targets : target.expr]]), "avg(container_memory_working_set_bytes{pod=~\"^worker(-(primary|canary))?-[^-]+-[^-]+$\", namespace=\"prod\"})"),
      contains(flatten([for panel in output.widget_result : [for target in panel.targets : target.expr]]), "sum(rate(container_network_receive_bytes_total{namespace=\"prod\", pod=~\"^service(-(primary|canary))?-[^-]+-[^-]+$\"}[5m]))"),
      contains(flatten([for panel in output.widget_result : [for target in panel.targets : target.expr]]), "sum(rate(container_network_receive_bytes_total{namespace=\"prod\", pod=~\"^gateway(-(primary|canary))?(-[^-]+)?-[^-]+$\"}[5m]))"),
      contains(flatten([for panel in output.widget_result : [for target in panel.targets : target.expr]]), "sum(rate(container_network_transmit_errors_total{namespace=\"prod\", pod=~\"^gateway(-(primary|canary))?(-[^-]+)?-[^-]+$\"}[5m]))"),
      contains(flatten([for panel in output.widget_result : [for target in panel.targets : target.expr]]), "sum(kube_pod_status_phase{namespace=\"prod\", pod=~\"^service(-(primary|canary))?-[^-]+-[^-]+$\"})"),
      contains(flatten([for panel in output.widget_result : [for target in panel.targets : target.expr]]), "avg(rate(container_cpu_usage_seconds_total{pod=~\"^worker(-(primary|canary))?-[^-]+-[^-]+$\", namespace=\"prod\"}[5m]))"),
      contains(flatten([for panel in output.widget_result : [for target in panel.targets : target.expr]]), "sum(rate(kube_pod_container_status_restarts_total{pod=~\"^worker(-(primary|canary))?-[^-]+-[^-]+$\"}[5m]))"),
    ])
    error_message = "omitting compatibility must preserve every affected modern dashboard query"
  }
}

run "explicit_false_keeps_the_modern_dashboard_query_contract" {
  command = plan

  module {
    source = "../../modules/dashboard"
  }

  variables {
    name             = "modern-false-query-contract"
    folder_name      = "dashboards"
    folder_name_uids = { dashboards = "dashboard-folder" }
    defaults = {
      period = "5m"
      query_compatibility = {
        legacy_dashboard_queries = false
      }
    }
    rows = [
      [
        { type = "container/memory", container = "service", namespace = "prod" },
        { type = "container/network", container = "service", namespace = "prod" },
        { type = "container/replicas", container = "service", namespace = "prod" },
      ],
      [
        { type = "ingress/memory", pod = "gateway", namespace = "prod" },
        { type = "container/network-traffic", pod = "gateway", namespace = "prod" },
        { type = "container/network-error", pod = "gateway", namespace = "prod" },
      ],
      [
        { type = "pod/cpu", pod = "worker", namespace = "prod" },
        { type = "pod/memory", pod = "worker", namespace = "prod" },
        { type = "pod/restarts", pod = "worker", namespace = "prod" },
      ],
    ]
  }

  assert {
    condition = alltrue([
      contains(flatten([for panel in output.widget_result : [for target in panel.targets : target.expr]]), "avg(container_memory_working_set_bytes{container=\"service\", namespace=\"prod\"})"),
      contains(flatten([for panel in output.widget_result : [for target in panel.targets : target.expr]]), "avg(container_memory_working_set_bytes{pod=~'(.+-)?gateway(-[^-]+)?-[^-]+$', namespace=\"prod\"})"),
      contains(flatten([for panel in output.widget_result : [for target in panel.targets : target.expr]]), "avg(container_memory_working_set_bytes{pod=~\"^worker(-(primary|canary))?-[^-]+-[^-]+$\", namespace=\"prod\"})"),
      contains(flatten([for panel in output.widget_result : [for target in panel.targets : target.expr]]), "sum(rate(container_network_receive_bytes_total{namespace=\"prod\", pod=~\"^service(-(primary|canary))?-[^-]+-[^-]+$\"}[5m]))"),
      contains(flatten([for panel in output.widget_result : [for target in panel.targets : target.expr]]), "sum(rate(container_network_receive_bytes_total{namespace=\"prod\", pod=~\"^gateway(-(primary|canary))?(-[^-]+)?-[^-]+$\"}[5m]))"),
      contains(flatten([for panel in output.widget_result : [for target in panel.targets : target.expr]]), "sum(rate(container_network_transmit_errors_total{namespace=\"prod\", pod=~\"^gateway(-(primary|canary))?(-[^-]+)?-[^-]+$\"}[5m]))"),
      contains(flatten([for panel in output.widget_result : [for target in panel.targets : target.expr]]), "sum(kube_pod_status_phase{namespace=\"prod\", pod=~\"^service(-(primary|canary))?-[^-]+-[^-]+$\"})"),
      contains(flatten([for panel in output.widget_result : [for target in panel.targets : target.expr]]), "avg(rate(container_cpu_usage_seconds_total{pod=~\"^worker(-(primary|canary))?-[^-]+-[^-]+$\", namespace=\"prod\"}[5m]))"),
      contains(flatten([for panel in output.widget_result : [for target in panel.targets : target.expr]]), "sum(rate(kube_pod_container_status_restarts_total{pod=~\"^worker(-(primary|canary))?-[^-]+-[^-]+$\"}[5m]))"),
    ])
    error_message = "explicit false must preserve every affected modern dashboard query"
  }
}
