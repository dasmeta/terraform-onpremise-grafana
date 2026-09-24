output "helm_metadata" {
  value       = helm_release.victoria_metrics.metadata
  description = "victoria metrics helm release metadata"
}

output "operator_release" {
  description = "Non-sensitive identity of the VictoriaMetrics Operator release."
  value = var.operator_enabled ? {
    name      = var.operator_release_name
    namespace = var.namespace
    chart     = "victoria-metrics-operator"
    version   = var.operator_chart_version
  } : null
}

output "resources_release" {
  description = "Non-sensitive identity of the Helm release that creates VictoriaMetrics custom-resource instances after the Operator CRDs."
  value = var.operator_enabled ? {
    name      = helm_release.victoria_metrics_resources[0].name
    namespace = helm_release.victoria_metrics_resources[0].namespace
    chart     = "victoria-metrics-resources"
  } : null
}

output "prometheus_converter_enabled" {
  value       = var.operator_enabled && var.prometheus_converter_enabled
  description = "Whether Prometheus monitor conversion is enabled for dual-backend migration compatibility."
}

output "native_node_scrapes" {
  value = {
    kubelet  = var.operator_enabled && var.agent_enabled && var.agent_kubelet_scrape_enabled
    cadvisor = var.operator_enabled && var.agent_enabled && var.agent_cadvisor_scrape_enabled
    resource = var.operator_enabled && var.agent_enabled && var.agent_resource_scrape_enabled
  }
  description = "Resolved native VMNodeScrape activation state."
}

output "native_kubernetes_component_scrapes" {
  value = {
    api_server = (
      var.agent_enabled &&
      var.operator_enabled &&
      var.agent_standalone &&
      var.agent_kubernetes_component_scrapes.api_server
    )
    core_dns = (
      var.agent_enabled &&
      var.operator_enabled &&
      var.agent_standalone &&
      var.agent_kubernetes_component_scrapes.core_dns
    )
    kube_proxy = (
      var.agent_enabled &&
      var.operator_enabled &&
      var.agent_standalone &&
      var.agent_kubernetes_component_scrapes.kube_proxy
    )
    controller_manager = (
      var.agent_enabled &&
      var.operator_enabled &&
      var.agent_standalone &&
      var.agent_kubernetes_component_scrapes.controller_manager
    )
    scheduler = (
      var.agent_enabled &&
      var.operator_enabled &&
      var.agent_standalone &&
      var.agent_kubernetes_component_scrapes.scheduler
    )
    etcd = (
      var.agent_enabled &&
      var.operator_enabled &&
      var.agent_standalone &&
      var.agent_kubernetes_component_scrapes.etcd
    )
  }
  description = "Rendered native Kubernetes component discovery state; these booleans do not report runtime target health."
}

output "resource_objects" {
  value = [
    for object in local.operator_objects : {
      api_version = object.apiVersion
      kind        = object.kind
      name        = object.metadata.name
      namespace   = object.metadata.namespace
    }
  ]
  description = "Non-sensitive identities of resources managed by the ordered custom-resource release."
}
