module "base" {
  source = "../../base"

  name        = "CPU [${var.period}m]"
  data_source = var.data_source
  coordinates = var.coordinates
  period      = var.period
  region      = var.region

  defaults = {
    MetricNamespace = "AWS/EC2"
    Namespace       = var.namespace
  }

  cloudwatch_targets = [
    {
      region      = var.region
      namespace   = "AWS/EC2"
      metric_name = "NetworkIn"
      period      = var.period
      statistic   = "Average"
      refId       = "A"
    },
    {
      region      = var.region
      namespace   = "AWS/EC2"
      metric_name = "NetworkOut"
      period      = var.period
      statistic   = "Average"
      refId       = "B"
    }
  ]

}
