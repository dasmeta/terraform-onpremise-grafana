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
    { label = "Avg", color = "FFC300", expression = "avg(rate(container_memory_usage_bytes{pod=~\"${var.pod}-[^-]+-[^-]+$\", namespace=\"${var.namespace}\"}[${var.period}m]))" },
    { label = "Max", color = "FF774D", expression = "max(rate(container_memory_usage_bytes{pod=~\"${var.pod}-[^-]+-[^-]+$\", namespace=\"${var.namespace}\"}[${var.period}m]))" },
    { label = "Request", color = "007CEF", expression = "max(kube_pod_container_resource_requests{pod=~\"${var.pod}-[^-]+-[^-]+$\", namespace=\"${var.namespace}\", resource=\"memory\"})" },
    { label = "Limit", color = "FF0F3C", expression = "max(kube_pod_container_resource_limits{pod=~\"${var.pod}-[^-]+-[^-]+$\", namespace=\"${var.namespace}\", resource=\"memory\"})" },
  ]
}
