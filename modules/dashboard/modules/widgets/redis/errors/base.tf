module "base" {
  source = "../../base"

  name              = "Errors"
  data_source       = var.data_source
  coordinates       = var.coordinates
  period            = var.period
  region            = var.region
  anomaly_detection = var.anomaly_detection
  anomaly_deviation = var.anomaly_deviation

  metrics = [
    { label = "__auto", expression = "sum(rate(redis_errors_total{service=\"${var.redis_name}\", namespace=\"${var.namespace}\"}[${var.period}])) by (err)" },
    { label = "__auto", expression = "sum(rate(redis_errors_total{service=\"${var.redis_name}\", namespace=\"${var.namespace}\"}[${var.period}]))" }
  ]
}
