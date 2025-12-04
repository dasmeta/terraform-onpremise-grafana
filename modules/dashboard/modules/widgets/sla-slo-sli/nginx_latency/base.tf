module "base" {
  source = "../../base"

  name        = "${var.histogram ? "Latency distribution" : "Latency"} (1d)"
  description = "${var.histogram ? "y-axis bars numbers are count of requests, x-axis each number is seconds and it means requests with {prev-number}<latency≤{number}, +inf means slower than 10(highest batch in list) seconds" : "percent of requests with latency≤2.5 seconds"} within 1 day"
  data_source = {
    uid  = var.datasource_uid
    type = "prometheus"
  }
  coordinates = var.coordinates
  decimals    = var.histogram ? null : 1
  period      = var.period
  type        = var.histogram ? "bargauge" : "gauge"
  fillOpacity = 80
  unit        = var.histogram ? null : "percent"

  options = {
    legend = {
      displayMode = "hidden"
    }
  }

  color_mode = var.histogram ? "palette-classic" : "thresholds"
  thresholds = var.histogram ? {} : {
    "steps" = [
      {
        "value" = null,
        "color" = "red"
      },
      {
        "value" = 90,
        "color" = "orange"
      },
      {
        "value" = 96,
        "color" = "yellow"
      },
      {
        "value" = 99,
        "color" = "green"
      }
    ]
  }

  metrics = var.histogram ? [
    { label : "__auto", format : "heatmap", expression : "sum by (le) (increase(nginx_ingress_controller_request_duration_seconds_bucket{status=~'[^1]..', ${var.filter}}[1d]))" },
    ] : [
    { label : "__auto", expression : "100 * sum(rate(nginx_ingress_controller_request_duration_seconds_bucket{le='2.5', status=~'[^1]..', ${var.filter}}[1d]))/sum(rate(nginx_ingress_controller_request_duration_seconds_bucket{le='+Inf', status=~'[^1]..', ${var.filter}}[1d]))" }
  ]
}
