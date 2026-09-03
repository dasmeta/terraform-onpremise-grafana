output "folder_uids" {
  value       = local.folder_name_uids
  description = "Map of folder names to folder UIDs for use by external modules"
}

output "grafana_url" {
  value       = try(module.grafana[0].grafana_url, "")
  description = "The URL of the Grafana instance"
}

output "grafana_admin_password" {
  value       = var.grafana_admin_password
  description = "The admin password for Grafana"
  sensitive   = true
}

output "metrics_collector" {
  value       = local.metrics_collector
  description = "The active metrics collector selected by metrics_collector."

  precondition {
    condition = (
      (
        local.metrics_collector == "prometheus" &&
        var.prometheus.enabled
      ) ||
      (
        local.metrics_collector == "victoria_metrics" &&
        var.victoria_metrics.enabled
      )
    )
    error_message = local.metrics_collector == "victoria_metrics" ? "victoria_metrics.enabled=true is required when metrics_collector is victoria_metrics." : "prometheus.enabled=true is required when metrics_collector is prometheus."
  }
}

output "metrics_collector_status" {
  value = {
    active                              = local.metrics_collector
    prometheus_installed                = var.prometheus.enabled
    victoria_metrics_installed          = var.victoria_metrics.enabled
    victoria_metrics_operator_installed = var.victoria_metrics.enabled
    prometheus_converter_enabled = (
      var.victoria_metrics.enabled
      ? module.victoria_metrics[0].prometheus_converter_enabled
      : false
    )
    victoria_metrics_standalone    = local.victoria_metrics_standalone
    prometheus_scraping_enabled    = local.prometheus_scraping_enabled
    victoria_metrics_agent_enabled = local.victoria_metrics_agent_enabled && var.victoria_metrics.enabled
    victoria_metrics_agent_name    = local.victoria_metrics_agent_enabled && var.victoria_metrics.enabled ? var.victoria_metrics.agent.name : null
    vm_node_scrapes = {
      kubelet  = local.victoria_metrics_agent_enabled && var.victoria_metrics.enabled && var.victoria_metrics.agent.kubelet_scrape_enabled
      cadvisor = local.victoria_metrics_agent_enabled && var.victoria_metrics.enabled && var.victoria_metrics.agent.cadvisor_scrape_enabled
      resource = local.victoria_metrics_agent_enabled && var.victoria_metrics.enabled && var.victoria_metrics.agent.resource_scrape_enabled
    }
    prometheus_remote_write_enabled   = var.victoria_metrics.enabled && local.prometheus_scraping_enabled
    default_datasource_uid            = local.default_metrics_datasource_uid
    victoria_metrics_remote_write_url = local.victoria_metrics_remote_write_url
    kube_state_metrics_installed      = var.kube_state_metrics.enabled
    kube_state_metrics_prometheus_monitor_enabled = (
      local.kube_state_metrics_prometheus_monitor_enabled
    )
    kube_state_metrics_vm_service_scrape_enabled = (
      local.kube_state_metrics_vm_service_scrape_enabled
    )
    kube_state_metrics_chart_version              = var.kube_state_metrics.chart_version
    kube_state_metrics_service_target             = local.kube_state_metrics_service_target
    node_exporter_installed                       = var.node_exporter.enabled
    node_exporter_prometheus_monitor_enabled      = local.node_exporter_prometheus_monitor_enabled
    node_exporter_vm_service_scrape_enabled       = local.node_exporter_vm_service_scrape_enabled
    node_exporter_chart_version                   = var.node_exporter.chart_version
    node_exporter_service_target                  = local.node_exporter_service_target
    selected_metrics_remote_write_url             = local.selected_metrics_remote_write_url
    tempo_metrics_generator_uses_selected_backend = local.tempo_metrics_generator_uses_selected_backend
    tempo_metrics_generator_remote_write_url = (
      local.tempo_metrics_generator_uses_selected_backend
      ? local.tempo_metrics_generator_remote_write_url
      : null
    )
    grafana_prometheus_monitor_enabled = local.grafana_prometheus_monitor_enabled
    tempo_prometheus_monitor_enabled   = local.tempo_prometheus_monitor_enabled
    loki_prometheus_monitor_enabled    = local.loki_prometheus_monitor_enabled
    vm_service_scrapes = {
      kube_state_metrics = local.kube_state_metrics_vm_service_scrape_enabled
      node_exporter      = local.node_exporter_vm_service_scrape_enabled
      tempo              = local.tempo_vm_service_scrape_enabled
      loki               = local.loki_vm_service_scrape_enabled
    }
  }
  description = "Resolved metrics collector installation and activation status."
}

output "alerts" {
  value       = try(module.alerts[0].rule_groups, {})
  description = "Information about created alert rule groups"
}


output "widget_alert_rules" {
  value       = try(values(module.application_dashboard)[0].widget_alert_rules, [])
  description = "Information about created widget alert rules"
}

output "blocks_by_type" {
  value = try(values(module.application_dashboard)[0].blocks_by_type, {})
}

output "all_folder_names" {
  value       = local.folder_name_uids
  description = "All folder names and uids"
}

output "service_alert_defaults" {
  value = try(values(module.application_dashboard)[0].service_alert_defaults, {})
}

output "service_alert_configs" {
  value = try(values(module.application_dashboard)[0].service_alert_configs, {})
}

output "application_dashboards" {
  value       = module.application_dashboard
  description = "application_dashboard sub-module outputs"
}

output "grafana" {
  value       = try(module.grafana[0], null)
  description = "grafana sub-module outputs"
}

output "prometheus" {
  value       = try(module.prometheus[0], null)
  description = "prometheus sub-module outputs"
}

output "kube_state_metrics" {
  value       = try(module.kube_state_metrics[0], null)
  description = "kube-state-metrics sub-module outputs"
}

output "node_exporter" {
  value       = try(module.node_exporter[0], null)
  description = "node-exporter sub-module outputs"
}

output "victoria_metrics" {
  value       = try(module.victoria_metrics[0], null)
  description = "VictoriaMetrics child-module outputs."
}

output "tempo" {
  value       = try(module.tempo[0], null)
  description = "tempo sub-module outputs"
}

output "loki" {
  value       = try(module.loki[0], null)
  description = "loki sub-module outputs"
}
