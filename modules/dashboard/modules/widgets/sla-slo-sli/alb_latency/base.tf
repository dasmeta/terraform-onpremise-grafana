module "base" {
  source = "../../base"

  name = "Latency"
  data_source = {
    uid  = var.datasource_uid
    type = "Cloudwatch"
  }
  coordinates = var.coordinates
  period      = var.period
  region      = var.region
  type        = "gauge"
  decimals    = 2
  color_mode  = "thresholds"

  thresholds = {
    mode = "absolute"
    steps = [
      {
        "value" = null,
        "color" = "green"
      },
      {
        "value" = 2,
        "color" = "orange"
      },
      {
        "value" = 2.5,
        "color" = "yellow"
      },
      {
        "value" = 3,
        "color" = "red"
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
      metric_name = "TargetResponseTime"
      period      = var.period
      statistic   = "Maximum"
      dimensions = {
        "LoadBalancer" = local.load_balancer_identifier
      }
      refId = "A"
      label = "Maximum"
    },
    {
      region      = var.region
      namespace   = "AWS/ApplicationELB"
      metric_name = "TargetResponseTime"
      period      = var.period
      statistic   = "Average"
      refId       = "B"
      dimensions = {
        "LoadBalancer" = local.load_balancer_identifier
      }
      label = "Average"
    }
  ]

}
