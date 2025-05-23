module "base" {
  source = "../../base"

  name = "Availability"
  data_source = {
    uid  = var.datasource_uid
    type = "Cloudwatch"
  }
  color_mode  = "thresholds"
  coordinates = var.coordinates
  period      = var.period
  region      = var.region
  view        = "gauge"
  decimals    = 2
  thresholds = {
    mode = "absolute"
    steps = [
      {
        color = "red"
        value = null
      },
      {
        color = "yellow"
        value = 80.00
      },
      {
        color = "light-green"
        value = 90.00
      },
      {
        color = "dark-green"
        value = 99.00
      }
    ]
  }

  defaults = {
    MetricNamespace = "AWS/EC2"
    Namespace       = var.namespace
  }

  cloudwatch_targets = [
    {
      region      = var.region
      namespace   = "AWS/ApplicationELB"
      metric_name = "RequestCount"
      period      = var.period
      statistic   = "Sum"
      dimensions = {
        "LoadBalancer" = local.load_balancer_identifier
      }
      refId = "A"
      hide  = true
    },
    {
      region      = var.region
      namespace   = "AWS/ApplicationELB"
      metric_name = "HTTPCode_ELB_5xx_Count"
      period      = var.period
      statistic   = "Sum"
      refId       = "B"
      dimensions = {
        "LoadBalancer" = local.load_balancer_identifier
      }
      hide = true
    }
  ]

  query = [{
    datasource = {
      type = "__expr__"
      uid  = "__expr__"
    }
    expression = "(1 - $B/$A)*100"
    refId      = "C"

    type = "math"
  }]

}
