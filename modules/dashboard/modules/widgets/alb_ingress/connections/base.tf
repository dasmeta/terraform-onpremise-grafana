module "base" {
  source = "../../base"

  name = "Connections"
  data_source = {
    uid  = var.datasource_uid
    type = "Cloudwatch"
  }

  coordinates = var.coordinates
  period      = var.period
  region      = var.region

  defaults = {}

  cloudwatch_targets = [
    {
      region      = var.region
      namespace   = "AWS/ApplicationELB"
      metric_name = "ActiveConnectionCount"
      period      = var.period
      statistic   = "Sum"
      refId       = "A"
      dimensions = merge({
        "LoadBalancer" : local.load_balancer_identifier
      }, var.dimensions)
    },
    {
      region      = var.region
      namespace   = "AWS/ApplicationELB"
      metric_name = "NewConnectionCount"
      period      = var.period
      statistic   = "Sum"
      refId       = "B"
      dimensions = merge({
        "LoadBalancer" : local.load_balancer_identifier
      }, var.dimensions)
    }
  ]

}
