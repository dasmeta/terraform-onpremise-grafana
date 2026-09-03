output "helm_metadata" {
  value       = helm_release.victoria_metrics.metadata
  description = "victoria metrics helm release metadata"
}

output "operator_release" {
  description = "Non-sensitive identity of the VictoriaMetrics Operator release."
  value = {
    name      = var.operator_release_name
    namespace = var.namespace
    chart     = "victoria-metrics-operator"
    version   = var.operator_chart_version
  }
}

output "resources_release" {
  description = "Non-sensitive identity of the Helm release that creates VictoriaMetrics custom-resource instances after the Operator CRDs."
  value = {
    name      = helm_release.victoria_metrics_resources.name
    namespace = helm_release.victoria_metrics_resources.namespace
    chart     = "victoria-metrics-resources"
  }
}

output "prometheus_converter_enabled" {
  value       = var.prometheus_converter_enabled
  description = "Whether Prometheus monitor conversion is enabled for dual-backend migration compatibility."
}

output "native_node_scrapes" {
  value = {
    kubelet  = var.agent_enabled && var.agent_kubelet_scrape_enabled
    cadvisor = var.agent_enabled && var.agent_cadvisor_scrape_enabled
    resource = var.agent_enabled && var.agent_resource_scrape_enabled
  }
  description = "Resolved native VMNodeScrape activation state."
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
