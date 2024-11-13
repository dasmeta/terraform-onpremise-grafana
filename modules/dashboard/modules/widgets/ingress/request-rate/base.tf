module "base" {
  source = "../../base"

  name              = "Requests rate (${var.ingress_type})${var.by_host ? " by host" : ""} [${var.period}m]"
  data_source       = var.data_source
  coordinates       = var.coordinates
  period            = var.period
  region            = var.region
  anomaly_detection = var.anomaly_detection
  anomaly_deviation = var.anomaly_deviation

  defaults = {
    MetricNamespace = "ContainerInsights"
    accountId       = var.account_id
  }

  metrics = var.by_host ? [
    { label : "__auto", color : "3ECE76", expression : "sum(rate(nginx_ingress_controller_requests[${var.period}m])) by (host)" },
    ] : [
    { label : "1m", color : "FFC300", expression : "sum(rate(nginx_ingress_controller_requests[1m]))" },
    { label : "5m", color : "FF774D", expression : "sum(rate(nginx_ingress_controller_requests[5m]))" },
    { label : "15m", color : "FF0F3C", expression : "sum(rate(nginx_ingress_controller_requests[15m]))" },
    { label : "${var.period}m range", color : "56F3D7", expression : "sum(rate(nginx_ingress_controller_requests[${var.period}m]))" }
  ]
}
