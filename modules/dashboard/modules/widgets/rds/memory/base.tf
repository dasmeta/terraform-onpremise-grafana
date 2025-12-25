module "base" {
  source = "../../base"

  name = "Memory (Freeable) Utilisation"
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
        metric_name = "FreeableMemory"
        period      = var.period
        statistic   = "Average"
        refId       = "A_${db_id}"
        dimensions  = { (local.dimension_key) = db_id }
        label       = ""
        hide        = false
      }
    ]
  ])
}
