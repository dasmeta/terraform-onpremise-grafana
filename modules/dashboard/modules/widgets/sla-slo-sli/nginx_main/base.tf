module "base" {
  source = "../../base"

  name = "Availability (1d)"
  data_source = {
    uid  = var.datasource_uid
    type = "prometheus"
  }
  coordinates = var.coordinates
  decimals    = 3
  stat        = "Sum"
  period      = var.period
  region      = var.region
  type        = "gauge"
  yAxis       = { left = { min = 85, max = 100 } }

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

  defaults = {
    MetricNamespace = "AWS/ApplicationELB"
    LoadBalancer    = var.balancer_name
  }

  metrics = [
    { label = "__auto", expression = "(1 - (sum(rate(nginx_ingress_controller_requests{status=~\"5[0-9][0-9]\"}[1d])) / sum(rate(nginx_ingress_controller_requests[1d])))) * 100" }
  ]
}
