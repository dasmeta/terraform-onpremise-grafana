module "base" {
  source = "../../base"

  name        = "${var.histogram ? "Status code distribution" : "Availability"} (1d)"
  description = "${var.histogram ? "count of requests for each http status code" : "percent of non 5xx status code requests"} within 1 day"
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
    { label : "__auto", format : "heatmap", expression : "sum by (status) (increase(nginx_ingress_controller_requests{${var.filter}}[1d]))" },
    ] : [
    { label = "__auto", expression = "(1 - (sum(rate(nginx_ingress_controller_requests{status=~\"5[0-9][0-9]\", ${var.filter}}[1d])) / sum(rate(nginx_ingress_controller_requests{${var.filter}}[1d])))) * 100" }
  ]
}
