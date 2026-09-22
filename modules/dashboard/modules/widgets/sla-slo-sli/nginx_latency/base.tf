module "base" {
  source = "../../base"

  name        = "${var.histogram ? "Latency distribution" : "Latency"} (${var.period})"
  description = "${var.histogram ? "Request-count distribution by duration bucket for successful responses" : "Request-weighted average duration of 2xx and 3xx responses in seconds"} within ${var.period}"
  data_source = {
    uid  = var.datasource_uid
    type = "prometheus"
  }
  coordinates = var.coordinates
  decimals    = var.histogram ? null : 3
  period      = var.period
  type        = var.histogram ? "bargauge" : "gauge"
  fillOpacity = 80
  unit        = var.histogram ? null : "s"

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
        "color" = "green"
      },
      {
        "value" = 2,
        "color" = "yellow"
      },
      {
        "value" = 2.5,
        "color" = "orange"
      },
      {
        "value" = 3,
        "color" = "red"
      }
    ]
  }

  metrics = var.histogram ? [
    { label : "__auto", format : "heatmap", expression : "sum by (le) (increase(nginx_ingress_controller_request_duration_seconds_bucket{status=~\"2..|3..\"${local.metric_filter_suffix}}[${var.period}]))" },
    ] : [
    { label : "__auto", expression : "sum(increase(nginx_ingress_controller_request_duration_seconds_sum{status=~\"2..|3..\"${local.metric_filter_suffix}}[${var.period}])) / sum(increase(nginx_ingress_controller_request_duration_seconds_count{status=~\"2..|3..\"${local.metric_filter_suffix}}[${var.period}]))" }
  ]
}
