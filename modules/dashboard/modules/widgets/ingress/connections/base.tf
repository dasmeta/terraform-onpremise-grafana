module "base" {
  source = "../../base"

  name = "Active Connections (${var.ingress_type})"
  data_source = {
    uid  = var.datasource_uid
    type = var.datasource_type
  }
  coordinates = var.coordinates
  period      = var.period
  region      = var.region

  defaults = {}

  cloudwatch_targets = var.ingress_type == "alb" ? [
    {
      region      = var.region
      namespace   = "AWS/ApplicationELB"
      metric_name = "ActiveConnectionCount"
      # period = var.period
      period    = ""
      statistic = "Sum"
      refId     = "A"
      dimensions = {
        "LoadBalancer" : "app/dev-ingress/8b813880d8b3d469"
      }
    },
  ] : []

  metrics = var.ingress_type == "nginx" ? [
    { label : "1m", color : "D400BF", expression : "sum(rate(nginx_ingress_controller_nginx_process_connections{${var.filter}}[1m]))" },
    { label : "5m", color : "007CEF", expression : "sum(rate(nginx_ingress_controller_nginx_process_connections{${var.filter}}[5m]))" },
    { label : "15m", color : "FFC300", expression : "sum(rate(nginx_ingress_controller_nginx_process_connections{${var.filter}}[15m]))" },
    { label : "(${var.period}) range", color : "7AAFF9", expression : "sum(rate(nginx_ingress_controller_nginx_process_connections{${var.filter}}[${var.period}]))" },
  ] : []
}
