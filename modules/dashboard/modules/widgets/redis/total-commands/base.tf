module "base" {
  source = "../../base"

  name              = "Total Commands"
  data_source       = var.data_source
  coordinates       = var.coordinates
  period            = var.period
  region            = var.region
  anomaly_detection = var.anomaly_detection
  anomaly_deviation = var.anomaly_deviation

  metrics = [
    { label = "__auto", expression = "sum(rate(redis_commands_total{service=\"${var.redis_name}\", namespace=\"${var.namespace}\"}[${var.period}])) by (cmd)" },
  ]
}
