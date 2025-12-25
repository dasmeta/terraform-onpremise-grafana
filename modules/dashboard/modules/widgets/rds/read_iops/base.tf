module "base" {
  source = "../../base"

  name = "IOPS (Read)"
  data_source = {
    uid  = var.datasource_uid
    type = "Cloudwatch"
  }
  coordinates = var.coordinates
  period      = var.period
  region      = var.region

  cloudwatch_targets = flatten([
    for db_id in var.db_identifiers : [
      {
        query_mode  = "Metrics"
        region      = var.region
        namespace   = "AWS/RDS"
        metric_name = "ReadIOPS"
        period      = var.period
        statistic   = "Average"
        refId       = "A_${db_id}"
        dimensions  = { (local.dimension_key) = db_id }
        label       = "${db_id} Avg"
        hide        = false
      },
      {
        query_mode  = "Metrics"
        region      = var.region
        namespace   = "AWS/RDS"
        metric_name = "ReadIOPS"
        period      = var.period
        statistic   = "Maximum"
        refId       = "B_${db_id}"
        dimensions  = { (local.dimension_key) = db_id }
        label       = "${db_id} Max"
        hide        = false
      }
    ]
  ])
}
