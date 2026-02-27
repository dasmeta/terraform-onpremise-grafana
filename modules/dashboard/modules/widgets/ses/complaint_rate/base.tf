module "base" {
  source = "../../base"

  name = "Current Complaint Rate"
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
      , { color = "#EAB839", value = 0.05 }
      , { color = "red", value = 0.1 }
    ]
  }

  cloudwatch_targets = [
    {
      query_mode  = "Metrics"
      region      = var.region
      namespace   = "AWS/SES"
      metric_name = "Reputation.ComplaintRate"
      period      = var.period
      statistic   = "Average"
      dimensions  = {}
      refId       = "A"
      label       = "Complaint Rate"
      hide        = false
    }
  ]
}
