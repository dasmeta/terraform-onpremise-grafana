module "base" {
  source = "../../base"

  name              = "Replicas"
  data_source       = var.data_source
  coordinates       = var.coordinates
  period            = var.period
  region            = var.region
  anomaly_detection = var.anomaly_detection
  anomaly_deviation = var.anomaly_deviation

  metrics = [
    { label = "Number", color = "1f77b4", expression = "sum(kube_deployment_status_replicas{deployment=\"${var.redis_name}\", namespace=\"${var.namespace}\"}) by (deployment)" },
  ]
}
