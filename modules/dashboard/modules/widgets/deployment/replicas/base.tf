module "base" {
  source = "../../base"

  name        = "Replicas"
  data_source = var.data_source
  coordinates = var.coordinates
  period      = var.period

  defaults = {
    MetricNamespace = "KubeStateMetrics"
  }

  metrics = [
    { label = "Replicas", color = "007CEF", expression = "sum(kube_deployment_status_replicas{deployment=\"${var.deployment}\", namespace=\"${var.namespace}\"})" },
  ]
}
