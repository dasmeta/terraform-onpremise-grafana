module "base" {
  source = "../../base"

  name = "Connections"
  data_source = {
    uid  = var.datasource_uid
    type = var.datasource_type
  }
  coordinates = var.coordinates
  period      = var.period
  region      = var.region

  defaults = {
    # MetricNamespace = "AWS/ApplicationELB"
    # Namespace       = var.namespace
  }

  cloudwatch_targets = [
    {
      region      = var.region
      namespace   = "AWS/ApplicationELB"
      metric_name = "ActiveConnectionCount"
      # period = var.period
      period    = "1"
      statistic = "Sum"
      refId     = "A"
      dimensions = merge({
        "LoadBalancer" : local.load_balancer_identifier
      }, var.dimensions)
    },
    {
      region      = var.region
      namespace   = "AWS/ApplicationELB"
      metric_name = "NewConnectionCount"
      period      = "1"
      statistic   = "Sum"
      refId       = "B"
      dimensions = {
        "LoadBalancer" : local.load_balancer_identifier
      }
    }
  ]

}
