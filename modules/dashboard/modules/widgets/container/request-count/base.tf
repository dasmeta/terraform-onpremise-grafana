module "base" {
  source = "../../base"

  name        = "Request Count ${var.only_5xx ? "5XX" : "All"} ${var.host} [${var.period}m]"
  data_source = var.data_source
  coordinates = var.coordinates
  period      = var.period

  defaults = {
    MetricNamespace = "AWS/ApplicationELB"
  }

  metrics = concat(
    var.only_5xx ? [] : [
      { label = "Total", expression = "sum(rate(nginx_ingress_controller_requests{host=\"${var.host}\"}[${var.period}m]))" },
      { label = "2xx", expression = "sum(rate(nginx_ingress_controller_requests{status=~\"2..\", host=\"${var.host}\"}[${var.period}m]))" },
      { label = "3xx", expression = "sum(rate(nginx_ingress_controller_requests{status=~\"3..\", host=\"${var.host}\"}[${var.period}m]))" },
      { label = "4xx", expression = "sum(rate(nginx_ingress_controller_requests{status=~\"4..\", host=\"${var.host}\"}[${var.period}m]))" },

    ],
    [
      { label = "499", expression = "sum(rate(nginx_ingress_controller_requests{status=\"499\", host=\"${var.host}\"}[${var.period}m]))" },
      { label = "5XX", expression = "sum(rate(nginx_ingress_controller_requests{status=~\"5..\", host=\"${var.host}\"}[${var.period}m]))" },
      { label = "500", expression = "sum(rate(nginx_ingress_controller_requests{status=\"500\", host=\"${var.host}\"}[${var.period}m]))" },
      { label = "502", expression = "sum(rate(nginx_ingress_controller_requests{status=\"502\", host=\"${var.host}\"}[${var.period}m]))" },
      { label = "503", expression = "sum(rate(nginx_ingress_controller_requests{status=\"503\", host=\"${var.host}\"}[${var.period}m]))" },
  ])
}
