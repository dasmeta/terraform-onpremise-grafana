module "base" {
  source = "../../base"

  name = "Requests rate (${var.ingress_type})${var.by_host ? " by host" : ""} [${var.period}m]"
  data_source = {
    uid  = var.datasource_uid
    type = var.datasource_type
  }
  coordinates = var.coordinates
  period      = var.period
  region      = var.region

  defaults = {}

  metrics = var.by_host ? [
    { label : "__auto", color : "3ECE76", expression : "sum(rate(nginx_ingress_controller_requests[${var.period}m])) by (host)" },
    ] : [
    { label : "1m", color : "FFC300", expression : "sum(rate(nginx_ingress_controller_requests[1m]))" },
    { label : "5m", color : "FF774D", expression : "sum(rate(nginx_ingress_controller_requests[5m]))" },
    { label : "15m", color : "FF0F3C", expression : "sum(rate(nginx_ingress_controller_requests[15m]))" },
    { label : "${var.period}m range", color : "56F3D7", expression : "sum(rate(nginx_ingress_controller_requests[${var.period}m]))" }
  ]
}
