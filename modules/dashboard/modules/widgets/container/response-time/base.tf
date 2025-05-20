module "base" {
  source = "../../base"

  name = "Response Time [${var.period}m]"
  data_source = {
    uid  = var.datasource_uid
    type = var.datasource_type
  }
  coordinates = var.coordinates
  period      = var.period

  defaults = {
    MetricNamespace = "AWS/ApplicationELB"
  }

  metrics = [
    { label = "Avg", expression = "avg(rate(nginx_ingress_controller_request_duration_seconds_sum{host=\"${var.host}\"}[${var.period}m])) / avg(rate(nginx_ingress_controller_request_duration_seconds_count{host=\"${var.host}\"}[${var.period}m]))" },
    { label = "Max", expression = "max(rate(nginx_ingress_controller_request_duration_seconds_sum{host=\"${var.host}\"}[${var.period}m])) / max(rate(nginx_ingress_controller_request_duration_seconds_count{host=\"${var.host}\"}[${var.period}m]))" },
    { label = "Acceptable", expression = "${var.acceptable}" },
    { label = "Problem", expression = "${var.problem}" },
  ]
}
