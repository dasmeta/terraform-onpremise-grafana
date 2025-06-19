module "base" {
  source = "../../base"

  name              = "Clients"
  data_source       = var.data_source
  coordinates       = var.coordinates
  period            = var.period
  region            = var.region
  anomaly_detection = var.anomaly_detection
  anomaly_deviation = var.anomaly_deviation

  type = "stat"

  metrics = [
    { label = "Clients", color : "808080", expression = "sum(redis_connected_clients{service=\"${var.redis_name}\", namespace=\"${var.namespace}\"})" }
  ]
}
