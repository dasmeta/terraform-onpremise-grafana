module "base" {
  source = "../../base"

  name = "${var.by_status_path ? "5XX Rate(5m) by (status, host, path) (> 0.01)" : var.only_5xx && !var.by_path ? "5XX Rate" : var.by_path ? "5XX Rate per Path (0.01)" : "All Requests Rate"} (${var.ingress_type})${var.by_host ? " by host" : ""} [${var.period}m]"
  data_source = {
    uid  = var.datasource_uid
    type = var.datasource_type
  }
  coordinates = var.coordinates
  period      = var.period
  region      = var.region

  defaults = {}

  options = {
    legend = {
      calcs       = ["lastNotNull", "max", "mean"]
      displayMode = "table"
      placement   = "right"
    }
  }

  metrics = var.only_5xx ? [
    { label : "5XX", color : "FF0F3C", expression : "sum(rate(nginx_ingress_controller_requests{status=~\"5..|499\"}[${var.period}m]))" },
    { label : var.by_path ? "{{path}}" : var.by_status_path ? "{{status}},{{path}}" : "__auto", color : "D400BF", expression : "sum(rate(nginx_ingress_controller_requests{status=~\"5..|499\"}[${var.period}m]))${var.by_path ? " by (path) > 0.01" : var.by_status_path ? "by (status, path, host) > 0.01" : " by (status)"}" }
    ] : [
    { label = var.by_host ? "{{host}}/Total" : "Total", color : "D400BF", expression = "sum(rate(nginx_ingress_controller_requests[${var.period}m]))${var.by_host ? " by (host)" : ""}" },
    { label = var.by_host ? "{{host}}/2xx" : "2xx", color : "3ECE76", expression = "sum(rate(nginx_ingress_controller_requests{status=~\"2..\"}[${var.period}m]))${var.by_host ? " by (host)" : ""}" },
    { label = var.by_host ? "{{host}}/3xx" : "3xx", color : "FFC300", expression = "sum(rate(nginx_ingress_controller_requests{status=~\"3..\"}[${var.period}m]))${var.by_host ? " by (host)" : ""}" },
    { label = var.by_host ? "{{host}}/4xx" : "4xx", color : "FF774D", expression = "sum(rate(nginx_ingress_controller_requests{status=~\"4..\"}[${var.period}m]))${var.by_host ? " by (host)" : ""}" },
    { label = var.by_host ? "{{host}}/5xx" : "5xx", color : "FF0F3C", display_mode : "table", expression = "sum(rate(nginx_ingress_controller_requests{status=~\"5..\"}[${var.period}m]))${var.by_host ? " by (host)" : ""}" },
  ]
}
