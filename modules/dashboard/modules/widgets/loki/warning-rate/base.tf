module "base" {
  source = "../../base"

  name              = "Warning Rate in Logs"
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
    { label = "warnings", expression = "sum(count_over_time({__aggregated_metric__=\"${var.aggregated_metric}\", level=~\"warn\"} [$__range])) or vector(0)/(sum(count_over_time({__aggregated_metric__=\"${var.aggregated_metric}\"} [$__range])) or vector(1))" }
  ]
}
