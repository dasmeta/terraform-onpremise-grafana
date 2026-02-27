module "base" {
  source = "../../base"

  name = "Current Bounce Rate"
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
      { color = "green", value = null }
      , { color = "#EAB839", value = 2.9996 }
      , { color = "red", value = 5 }
    ]
  }

  cloudwatch_targets = [
    {
      query_mode  = "Metrics"
      region      = var.region
      namespace   = "AWS/SES"
      metric_name = "Reputation.BounceRate"
      period      = var.period
      statistic   = "Average"
      dimensions  = {}
      refId       = "A"
      label       = "Bounce Rate"
      hide        = false
    }
  ]
}
