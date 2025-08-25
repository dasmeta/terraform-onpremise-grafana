module "base" {
  source = "../../base"

  name = "Replicas"

  data_source = {
    uid  = var.datasource_uid
    type = "prometheus"
  }
  coordinates = var.coordinates
  period      = var.period

  metrics = [
    { label = "Replicas", color = "007CEF", expression = "sum(kube_deployment_status_replicas{deployment=\"${var.deployment}\", namespace=\"${var.namespace}\"})" },
  ]
}
