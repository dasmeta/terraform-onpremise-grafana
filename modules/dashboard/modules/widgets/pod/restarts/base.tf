module "base" {
  source = "../../base"

  name = "Restarts"
  data_source = {
    uid  = var.datasource_uid
    type = "prometheus"
  }
  coordinates = var.coordinates
  period      = var.period

  metrics = [
    { label = "Restarts", color = "FF0F3C", expression = "sum(rate(kube_pod_container_status_restarts_total{pod=~\"^${var.pod}-[^-]+-[^-]+$\"}[${var.period}]))" },
  ]
}
