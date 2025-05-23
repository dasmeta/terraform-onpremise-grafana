module "base" {
  source = "../../base"

  name = "${var.histogram ? "Request Duration histogram" : "Latency"} [${var.period}m]"
  data_source = {
    uid  = var.datasource_uid
    type = "prometheus"
  }
  coordinates = var.coordinates
  decimals    = var.histogram ? null : 3
  period      = var.period
  region      = var.region
  view        = var.histogram ? "histogram" : "gauge"
  fillOpacity = 80

  defaults = {
    MetricNamespace = "AWS/ApplicationELB"
    LoadBalancer    = var.balancer_name
    accountId       = var.account_id
  }

  metrics = var.histogram ? [
    { label : "Duration", expression : "histogram_quantile(0.90, sum(rate(nginx_ingress_controller_request_duration_seconds_bucket[${var.period}m])) by (le))" },
    ] : [
    { label : "AVG", expression : "avg(increase(nginx_ingress_controller_request_duration_seconds_sum[${var.period}m])) / 10" },
    { label : "MAX", expression : "max(increase(nginx_ingress_controller_request_duration_seconds_sum[${var.period}m])) / 10" }
  ]
}
