module "base" {
  source = "../../base"

  name              = "Logs"
  data_source       = var.data_source
  coordinates       = var.coordinates
  period            = var.period
  region            = var.region
  anomaly_detection = var.anomaly_detection
  anomaly_deviation = var.anomaly_deviation

  defaults = {
    MetricNamespace = "ContainerInsights"
  }

  metrics = [
    { label = "error", expression = "count_over_time({__aggregated_metric__=\"${var.aggregated_metric}\",level=~\"error|fatal|exception\"}[$__range])" }
  ]
}
