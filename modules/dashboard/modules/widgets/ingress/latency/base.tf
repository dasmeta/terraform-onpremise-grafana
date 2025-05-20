module "base" {
  source = "../../base"

  name = "Latency (${var.ingress_type})${var.by_host ? " by host" : ""} [${var.period}m]"
  data_source = {
    uid  = var.datasource_uid
    type = var.datasource_type
  }
  coordinates = var.coordinates
  period      = var.period
  region      = var.region

  defaults = {
    MetricNamespace = "ContainerInsights"
  }

  metrics = var.by_host ? [
    { label : "Avg", color : "7AAFF9", expression : "avg(increase(nginx_ingress_controller_request_duration_seconds_sum[${var.period}m]))" },
    { label : "__auto", expression : "max by (path) (rate(nginx_ingress_controller_request_duration_seconds_sum[${var.period}m])) > 1" },
    ] : [
    { label = "Avg", color : "FFC300", expression = "avg(rate(nginx_ingress_controller_request_duration_seconds_sum[${var.period}m]))" },
    { label = "Max", color : "7AAFF9", expression = "max(rate(nginx_ingress_controller_request_duration_seconds_sum[${var.period}m]))" },
    { label = "Acceptable", color : "3ECE76", expression = "${var.acceptable}" },
    { label = "Problem", color : "FF0F3C", expression = "${var.problem}" },
  ]
}
