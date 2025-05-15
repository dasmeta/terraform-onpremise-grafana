module "base" {
  source = "../../base"

  name        = "Memory"
  data_source = var.data_source
  coordinates = var.coordinates
  period      = var.period
  unit        = "bytes"

  defaults = {
    MetricNamespace = "ContainerInsights"
    Namespace       = var.namespace
    PodName         = var.container
  }

  metrics = [
    { label = "Avg", color = "FFC300", expression = "avg(container_memory_usage_bytes{container=\"${var.container}\", namespace=\"${var.namespace}\"})" },
    { label = "Max", color = "FF774D", expression = "max(container_memory_usage_bytes{container=\"${var.container}\", namespace=\"${var.namespace}\"})" },
    { label = "Request", color = "007CEF", expression = "avg(kube_pod_container_resource_requests{container=\"${var.container}\", namespace=\"${var.namespace}\", resource=\"memory\"})" },
    { label = "Limit", color = "FF0F3C", expression = "avg(kube_pod_container_resource_limits{container=\"${var.container}\", namespace=\"${var.namespace}\", resource=\"memory\"})" },
  ]
}
