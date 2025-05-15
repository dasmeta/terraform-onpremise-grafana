module "base" {
  source = "../../base"

  name        = "Restarts [${var.period}m]"
  data_source = var.data_source
  coordinates = var.coordinates
  period      = var.period

  defaults = {
    MetricNamespace = "ContainerInsights"
    Namespace       = var.namespace
  }

  metrics = [
    { label = "Restarts", color = "FF0F3C", expression = "sum(rate(kube_pod_container_status_restarts_total{pod=~\"^${var.pod}-[^-]+-[^-]+$\"}[${var.period}m]))" },
  ]
}
