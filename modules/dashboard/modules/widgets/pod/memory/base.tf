locals {
  pod_matcher = var.legacy_dashboard_queries ? "${var.pod}-[^-]+-[^-]+$" : "^${var.pod}(-(primary|canary))?-[^-]+-[^-]+$"
}

module "base" {
  source = "../../base"

  name        = "Memory"
  data_source = var.data_source
  coordinates = var.coordinates
  period      = var.period
  unit        = "bytes"

  defaults = {
    MetricNamespace = "ContainerInsights"
    PodName         = var.pod
  }

  metrics = [
    { label = "Avg", color = "FFC300", expression = var.legacy_dashboard_queries ? "avg(rate(container_memory_usage_bytes{pod=~\"${local.pod_matcher}\", namespace=\"${var.namespace}\"}[${var.period}]))" : "avg(container_memory_working_set_bytes{pod=~\"${local.pod_matcher}\", namespace=\"${var.namespace}\"})" },
    { label = "Max", color = "FF774D", expression = var.legacy_dashboard_queries ? "max(rate(container_memory_usage_bytes{pod=~\"${local.pod_matcher}\", namespace=\"${var.namespace}\"}[${var.period}]))" : "max(container_memory_working_set_bytes{pod=~\"${local.pod_matcher}\", namespace=\"${var.namespace}\"})" },
    { label = "Request", color = "007CEF", expression = "max(kube_pod_container_resource_requests{pod=~\"${local.pod_matcher}\", namespace=\"${var.namespace}\", resource=\"memory\"})" },
    { label = "Limit", color = "FF0F3C", expression = "max(kube_pod_container_resource_limits{pod=~\"${local.pod_matcher}\", namespace=\"${var.namespace}\", resource=\"memory\"})" },
  ]
}
