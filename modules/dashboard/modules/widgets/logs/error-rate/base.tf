module "base" {
  source = "../../base"

  name        = "Error Rate in Logs"
  data_source = var.data_source
  coordinates = var.coordinates
  period      = var.period

  metrics = [
    { label = "errors", expression = "sum(count_over_time({__aggregated_metric__=\"${var.aggregated_metric}\", level=~\"error|fatal|exception\"} [$__range])) or vector(0)/(sum(count_over_time({__aggregated_metric__=\"${var.aggregated_metric}\"} [$__range])) or vector(1))" }
  ]
}
