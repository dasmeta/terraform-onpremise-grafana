module "base" {
  source = "../../base"

  name              = "CPU [${var.period}m]"
  data_source       = var.data_source
  coordinates       = var.coordinates
  period            = var.period
  region            = var.region
  anomaly_detection = var.anomaly_detection
  anomaly_deviation = var.anomaly_deviation

  defaults = {
    MetricNamespace = "ContainerInsights"
    ClusterName     = var.cluster
    Namespace       = var.namespace
    PodName         = var.container
  }

  metrics = var.by_pod ? [
    { label = "__auto", color = "FFC300", expression = "avg(rate(container_cpu_usage_seconds_total{container=\"${var.container}\", namespace=\"${var.namespace}\"}[${var.period}m])) by (pod)" },
    { label = "__auto", color = "FF774D", expression = "max(rate(container_cpu_usage_seconds_total{container=\"${var.container}\", namespace=\"${var.namespace}\"}[${var.period}m])) by (pod)" },
    { label = "Request", color = "007CEF", expression = "avg(kube_pod_container_resource_requests{container=\"${var.container}\", namespace=\"${var.namespace}\", resource=\"cpu\"})" },
    { label = "Limit", color = "FF0F3C", expression = "avg(kube_pod_container_resource_limits{container=\"${var.container}\", namespace=\"${var.namespace}\", resource=\"cpu\"})" },
    ] : [
    { label = "Avg", color = "FFC300", expression = "avg(rate(container_cpu_usage_seconds_total{container=\"${var.container}\", namespace=\"${var.namespace}\"}[${var.period}m]))" },
    { label = "Max", color = "FF774D", expression = "max(rate(container_cpu_usage_seconds_total{container=\"${var.container}\", namespace=\"${var.namespace}\"}[${var.period}m]))" },
    { label = "Request", color = "007CEF", expression = "max(kube_pod_container_resource_requests{container=\"${var.container}\", namespace=\"${var.namespace}\", resource=\"cpu\"})" },
    { label = "Limit", color = "FF0F3C", expression = "max(kube_pod_container_resource_limits{container=\"${var.container}\", namespace=\"${var.namespace}\", resource=\"cpu\"})" },
  ]
}
