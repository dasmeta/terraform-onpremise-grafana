module "base" {
  source = "../../base"

  name = "Bounces by Configuration Set (Time Series)"
  data_source = {
    uid  = var.datasource_uid
    type = "Cloudwatch"
  }
  coordinates = var.coordinates
  period      = var.period
  region      = var.region

  thresholds = {
    mode = "absolute"
    steps = [
      { color = "green", value = null },
      { color = "red", value = 80 }
    ]
  }

  cloudwatch_targets = [
    {
      query_mode  = "Metrics"
      region      = var.region
      namespace   = "AWS/SES"
      metric_name = "Bounce"
      period      = var.period
      statistic   = "Average"
      dimensions  = {}
      refId       = "A"
      label       = "Bounce"
      hide        = false
    }
  ]
}
