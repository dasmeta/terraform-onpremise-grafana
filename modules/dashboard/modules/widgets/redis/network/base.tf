module "base" {
  source = "../../base"

  name              = "Network"
  data_source       = var.data_source
  coordinates       = var.coordinates
  period            = var.period
  region            = var.region
  anomaly_detection = var.anomaly_detection
  anomaly_deviation = var.anomaly_deviation

  metrics = [
    { label = "In", color : "17becf", expression = "sum(rate(redis_net_input_bytes_total{service=\"${var.redis_name}\", namespace=\"${var.namespace}\"}[${var.period}])) / 1024 / 1024" },
    { label = "Out", color : "e377c2", expression = "sum(rate(redis_net_output_bytes_total{service=\"${var.redis_name}\", namespace=\"${var.namespace}\"}[${var.period}])) / 1024 / 1024" }
  ]
}
