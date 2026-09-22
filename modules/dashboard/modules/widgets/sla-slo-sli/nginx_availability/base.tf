module "base" {
  source = "../../base"

  name        = "${var.histogram ? "Status code distribution" : "Availability"} (${var.period})"
  description = "${var.histogram ? "Count of requests for each HTTP status code" : "Percent of requests that did not return a 5xx status"} within ${var.period}"
  data_source = {
    uid  = var.datasource_uid
    type = "prometheus"
  }
  coordinates = var.coordinates
  decimals    = var.histogram ? null : 1
  stat        = "Sum"
  period      = var.period
  type        = var.histogram ? "bargauge" : "gauge"
  yAxis       = { left = { min = 85, max = 100 } }
  unit        = var.histogram ? null : "percent"
  fillOpacity = 80

  start = "-PT8640H"
  trend = false
  end   = "P0D"
  annotations = {
    horizontal = [
      {
        color : "#3ECE76",
        label : "Great",
        value : 99.9,
        fill : "below"
      },
      {
        color : "#FFC300",
        label : "Good",
        value : 99,
        fill : "below"
      },
      {
        color : "#FF0F3C",
        label : "Bad",
        value : 90,
        fill : "below"
      }
    ]
  }

  options = {
    legend = {
      displayMode = "hidden"
    }
  }

  color_mode = var.histogram ? "palette-classic" : "thresholds"
  thresholds = var.histogram ? {} : {
    "steps" : [
      {
        "value" : null,
        "color" : "red"
      },
      {
        "value" : 90,
        "color" : "orange"
      },
      {
        "value" : 96,
        "color" : "yellow"
      },
      {
        "value" : 99,
        "color" : "green"
      }
    ]
  }

  metrics = var.histogram ? [
    { label : "__auto", format : "heatmap", expression : "sum by (status) (increase(nginx_ingress_controller_requests{${local.metric_filter}}[${var.period}]))" },
    ] : [
    { label = "__auto", expression = "100 * sum(increase(nginx_ingress_controller_requests{status!~\"5..\"${local.metric_filter_suffix}}[${var.period}])) / sum(increase(nginx_ingress_controller_requests{${local.metric_filter}}[${var.period}]))" }
  ]
}
