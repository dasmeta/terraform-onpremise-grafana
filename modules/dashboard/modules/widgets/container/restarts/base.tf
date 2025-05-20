module "base" {
  source = "../../base"

  name = "Restarts [${var.period}m]"
  data_source = {
    uid  = var.datasource_uid
    type = var.datasource_type
  }
  coordinates = var.coordinates
  stat        = "Maximum"
  period      = var.period

  defaults = {
    MetricNamespace = "ContainerInsights"
  }

  metrics = [
    { label = "Restarts", expression = "sum(rate(kube_pod_container_status_restarts_total{container=\"${var.container}\", namespace=\"${var.namespace}\"}[${var.period}m])) by (container)" },
  ]
}
