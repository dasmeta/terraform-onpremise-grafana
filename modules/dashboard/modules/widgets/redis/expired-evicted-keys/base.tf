module "base" {
  source = "../../base"

  name              = "Expired / Evicted Keys"
  data_source       = var.data_source
  coordinates       = var.coordinates
  period            = var.period
  region            = var.region
  anomaly_detection = var.anomaly_detection
  anomaly_deviation = var.anomaly_deviation

  metrics = [
    { label = "Expired", color : "ffc300", expression = "sum(rate(redis_expired_keys_total{service=\"${var.redis_name}\", namespace=\"${var.namespace}\"}[${var.period}])) by (service)" },
    { label = "Evicted", color : "ff0f3c", expression = "sum(rate(redis_evicted_keys_total{service=\"${var.redis_name}\", namespace=\"${var.namespace}\"}[${var.period}])) by (service)" },
  ]
}
