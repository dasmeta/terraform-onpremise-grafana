module "base" {
  source = "../../base"

  name              = "Total Memory Usage"
  data_source       = var.data_source
  coordinates       = var.coordinates
  period            = var.period
  region            = var.region
  anomaly_detection = var.anomaly_detection
  anomaly_deviation = var.anomaly_deviation

  unit = "bytes"

  metrics = [
    { label = "Used", color = "007cef", expression = "redis_memory_used_bytes{service=\"${var.redis_name}\", namespace=\"${var.namespace}\"}" },
    { label = "Max", color = "d400bf", expression = "redis_memory_max_bytes{service=\"${var.redis_name}\", namespace=\"${var.namespace}\"}" }
  ]
}
