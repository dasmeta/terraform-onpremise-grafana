module "base" {
  source = "../../base"

  name              = "Memory"
  data_source       = var.data_source
  coordinates       = var.coordinates
  period            = var.period
  region            = var.region
  anomaly_detection = var.anomaly_detection
  anomaly_deviation = var.anomaly_deviation
  unit              = "bytes"

  defaults = {
    MetricNamespace = "ContainerInsights"
    ClusterName     = var.cluster
    Namespace       = var.namespace
    PodName         = var.container
    accountId       = var.account_id
  }

  metrics = [
    { label = "Avg", color = "FFC300", expression = "avg(container_memory_usage_bytes{container=\"${var.container}\", namespace=\"${var.namespace}\"})" },
    { label = "Max", color = "FF774D", expression = "max(container_memory_usage_bytes{container=\"${var.container}\", namespace=\"${var.namespace}\"})" },
    { label = "Request", color = "007CEF", expression = "avg(kube_pod_container_resource_requests{container=\"${var.container}\", namespace=\"${var.namespace}\", resource=\"memory\"})" },
    { label = "Limit", color = "FF0F3C", expression = "avg(kube_pod_container_resource_limits{container=\"${var.container}\", namespace=\"${var.namespace}\", resource=\"memory\"})" },
  ]
}
