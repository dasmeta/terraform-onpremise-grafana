mock_provider "grafana" {}
mock_provider "random" {}

run "legacy_service_block_mode_preserves_deployed_queries" {
  command = plan

  variables {
    name             = "legacy-service-block-contract"
    folder_name      = "dashboards"
    folder_name_uids = { dashboards = "dashboard-folder" }
    data_source      = { uid = "prometheus", type = "prometheus" }
    defaults = {
      query_compatibility = {
        legacy_dashboard_queries     = true
        legacy_service_block_queries = true
      }
    }
    alerts = { enabled = true }
    rows = [
      { type = "block/service", name = "example-service", namespace = "prod" },
    ]
  }

  assert {
    condition = alltrue([
      contains(compact(flatten([for panel in output.widget_result : [for target in try(panel.targets, []) : try(target.expr, null)]])), "sum(kube_pod_status_phase{namespace=\"prod\", pod=~\"example-service-.*\"})"),
      contains(compact(flatten([for panel in output.widget_result : [for target in try(panel.targets, []) : try(target.expr, null)]])), "sum(kube_pod_status_phase{namespace=\"prod\", pod=~\"example-service-.*\"}) by (phase)"),
      contains(compact(flatten([for panel in output.widget_result : [for target in try(panel.targets, []) : try(target.expr, null)]])), "sum(rate(kube_pod_container_status_restarts_total{namespace=\"prod\", pod=~\"^example-service-[^-]+-[^-]+$\"}[$__rate_interval])) by (container)"),
      contains(compact([for rule in output.widget_alert_rules : try(rule.expr, null)]), "sum(kube_pod_status_phase{namespace='prod', pod=~'^example-service(-[^-]+)?-[^-]+$', phase!='Succeeded', phase!='Running'}) by (phase)"),
      contains(compact([for rule in output.widget_alert_rules : try(rule.expr, null)]), "(sum(container_memory_usage_bytes{container='example-service', namespace='prod'}) by (pod) / max(kube_pod_container_resource_limits{container='example-service', namespace='prod', resource='memory'}) by (pod)) * 100"),
    ])
    error_message = "legacy service block mode must preserve deployed status and alert expressions"
  }
}

run "omitted_service_block_mode_keeps_modern_queries" {
  command = plan

  variables {
    name             = "modern-service-block-contract"
    folder_name      = "dashboards"
    folder_name_uids = { dashboards = "dashboard-folder" }
    data_source      = { uid = "prometheus", type = "prometheus" }
    alerts           = { enabled = true }
    rows = [
      { type = "block/service", name = "example-service", namespace = "prod" },
    ]
  }

  assert {
    condition = alltrue([
      contains(compact(flatten([for panel in output.widget_result : [for target in try(panel.targets, []) : try(target.expr, null)]])), "sum(kube_pod_status_phase{namespace=\"prod\", pod=~\"^example-service(-(primary|canary))?-[^-]+-[^-]+$\"})"),
      contains(compact([for rule in output.widget_alert_rules : try(rule.expr, null)]), "sum(kube_pod_status_phase{namespace='prod', pod=~'^example-service(-(primary|canary))?(-[^-]+)?-[^-]+$', phase!='Succeeded', phase!='Running'}) by (phase)"),
      contains(compact([for rule in output.widget_alert_rules : try(rule.expr, null)]), "(sum(container_memory_working_set_bytes{container='example-service', namespace='prod'}) by (pod) / max(kube_pod_container_resource_limits{container='example-service', namespace='prod', resource='memory'}) by (pod)) * 100"),
    ])
    error_message = "omitting service block compatibility must preserve modern status and alert expressions"
  }
}
