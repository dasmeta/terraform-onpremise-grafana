module "base" {
  source = "../../base"

  name = "Sending Rate (Messages per Second)"
  data_source = {
    uid  = var.datasource_uid
    type = "Cloudwatch"
  }
  coordinates = var.coordinates
  period      = var.period
  region      = var.region

  # Send sum per 60s → divide by 60 for messages per second
  transformations = [
    {
      id = "calculateField"
      options = {
        alias = "Msg per second"
        mode  = "binary"
        binary = {
          left = {
            matcher = {
              id      = "byName"
              options = "Send"
            }
          }
          operator = "/"
          right = {
            fixed = "60"
          }
        }
        reduce = {
          reducer = "sum"
        }
      }
    }
  ]

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
      label       = "Send"
      hide        = false
    }
  ]
}
