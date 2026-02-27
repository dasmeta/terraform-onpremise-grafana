module "base" {
  source = "../../base"

  name = "Sending Quota (24-Hour Rolling Window)"
  data_source = {
    uid  = var.datasource_uid
    type = "Cloudwatch"
  }
  coordinates = var.coordinates
  period      = var.period
  region      = var.region
  type        = "gauge"
  color_mode  = "thresholds"

  # Calculation: Total (sum of all values) — instead of Last
  reduce_options = {
    calcs  = ["sum"]
    fields = ""
    values = false
  }

  # Standard options: min/max (configurable)
  standard_options = var.standard_options

  defaults = {}

  thresholds = {
    mode = "percentage"
    steps = [
      { color = "green", value = null }
      , { color = "red", value = 85 }
    ]
  }

  # Gauge shows Send sum; max 100000 for quota display
  cloudwatch_targets = [
    {
      query_mode  = "Metrics"
      region      = var.region
      namespace   = "AWS/SES"
      metric_name = "Send"
      period      = var.period
      statistic   = "Sum"
      dimensions  = {}
      refId       = "A"
      label       = ""
      hide        = false
    }
  ]
}
