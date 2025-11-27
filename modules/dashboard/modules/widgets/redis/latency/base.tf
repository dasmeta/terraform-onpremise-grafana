module "base" {
  source = "../../base"

  name              = "Latency"
  data_source       = var.data_source
  coordinates       = var.coordinates
  period            = var.period
  region            = var.region
  anomaly_detection = var.anomaly_detection
  anomaly_deviation = var.anomaly_deviation

  metrics = [
    { label = "Percentile", color : "3ece76", expression = "sum(rate(redis_latency_percentiles_usec_sum{service=\"${var.redis_name}\", namespace=\"${var.namespace}\"}[${var.period}])) / 60 / 60 / 60" },
    { label = "Command Duration", color : "d400bf", expression = "sum(rate(redis_commands_duration_seconds_total{service=\"${var.redis_name}\", namespace=\"${var.namespace}\"}[${var.period}]))" }
  ]
}
