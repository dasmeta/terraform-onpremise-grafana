module "base" {
  source = "../../base"

  name              = "CPU"
  data_source       = var.data_source
  coordinates       = var.coordinates
  period            = var.period
  region            = var.region
  anomaly_detection = var.anomaly_detection
  anomaly_deviation = var.anomaly_deviation

  metrics = [
    { label = "User", color = "e377c2", expression = "sum(rate(redis_cpu_user_seconds_total{service=\"${var.redis_name}\", namespace=\"${var.namespace}\"}[${var.period}]))" },
    { label = "System", color = "17becf", expression = "sum(rate(redis_cpu_sys_seconds_total{service=\"${var.redis_name}\", namespace=\"${var.namespace}\"}[${var.period}]))" }
  ]
}
