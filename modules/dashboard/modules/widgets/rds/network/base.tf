module "base" {
  source = "../../base"

  name = "Network"
  data_source = {
    uid  = var.datasource_uid
    type = "Cloudwatch"
  }
  coordinates = var.coordinates
  period      = var.period
  region      = var.region
  unit        = "bytes"

  cloudwatch_targets = flatten([
    for db_id in var.db_identifiers : [
      {
        query_mode  = "Metrics"
        region      = var.region
        namespace   = "AWS/RDS"
        metric_name = "NetworkReceiveThroughput"
        period      = var.period
        statistic   = "Average"
        refId       = "A_${db_id}"
        dimensions  = { (local.dimension_key) = db_id }
        label       = "${db_id} Receive Avg"
        hide        = false
      },
      {
        query_mode  = "Metrics"
        region      = var.region
        namespace   = "AWS/RDS"
        metric_name = "NetworkReceiveThroughput"
        period      = var.period
        statistic   = "Maximum"
        refId       = "B_${db_id}"
        dimensions  = { (local.dimension_key) = db_id }
        label       = "${db_id} Receive Max"
        hide        = false
      },
      {
        query_mode  = "Metrics"
        region      = var.region
        namespace   = "AWS/RDS"
        metric_name = "NetworkTransmitThroughput"
        period      = var.period
        statistic   = "Average"
        refId       = "C_${db_id}"
        dimensions  = { (local.dimension_key) = db_id }
        label       = "${db_id} Transmit Avg"
        hide        = false
      },
      {
        query_mode  = "Metrics"
        region      = var.region
        namespace   = "AWS/RDS"
        metric_name = "NetworkTransmitThroughput"
        period      = var.period
        statistic   = "Maximum"
        refId       = "D_${db_id}"
        dimensions  = { (local.dimension_key) = db_id }
        label       = "${db_id} Transmit Max"
        hide        = false
      }
    ]
  ])
}
