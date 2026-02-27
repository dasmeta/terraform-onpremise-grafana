module "base" {
  source = "../../base"

  name = "Bounce/Reject"
  data_source = {
    uid  = var.datasource_uid
    type = "Cloudwatch"
  }
  coordinates = var.coordinates
  period      = "3600"
  region      = var.region
  fillOpacity = 10

  options = {
    legend = {
      calcs       = ["min", "max", "mean"]
      displayMode = "table"
      placement   = "bottom"
      show_legend = true
    }
    tooltip = {
      mode = "multi"
      sort = "none"
    }
  }

  cloudwatch_targets = [
    {
      query_mode  = "Metrics"
      region      = var.region
      namespace   = "AWS/SES"
      metric_name = "Bounce"
      period      = "3600"
      statistic   = "Sum"
      dimensions  = {}
      refId       = "A"
      label       = "Bounce"
      hide        = false
    },
    {
      query_mode  = "Metrics"
      region      = var.region
      namespace   = "AWS/SES"
      metric_name = "Reject"
      period      = "3600"
      statistic   = "Sum"
      dimensions  = {}
      refId       = "B"
      label       = "Reject"
      hide        = false
    }
  ]
}
