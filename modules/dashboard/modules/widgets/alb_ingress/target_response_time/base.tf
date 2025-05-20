module "base" {
  source = "../../base"

  name = "Target Respons Time"
  data_source = {
    uid  = var.datasource_uid
    type = var.datasource_type
  }
  coordinates = var.coordinates
  period      = var.period
  region      = var.region

  defaults = {
    # MetricNamespace = "AWS/EC2"
    # Namespace       = var.namespace
  }

  cloudwatch_targets = [
    {
      region      = var.region
      namespace   = "AWS/ApplicationELB"
      metric_name = "TargetResponseTime"
      period      = "1"
      statistic   = "Average"
      refId       = "A"
      dimensions = merge({
        "LoadBalancer" : local.load_balancer_identifier
      }, var.dimensions)
    }
  ]

}
