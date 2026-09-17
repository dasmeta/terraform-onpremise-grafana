module "base" {
  source = "../../base"

  name = "Bytes Out"
  data_source = {
    uid  = var.datasource_uid
    type = "Cloudwatch"
  }
  coordinates = var.coordinates
  period      = var.period
  region      = var.region
  unit        = "Bps"

  cloudwatch_targets = [
    for cluster in var.cluster_names : {
      query_mode  = "Metrics"
      region      = var.region
      namespace   = "AWS/Kafka"
      metric_name = "BytesOutPerSec"
      period      = var.period
      statistic   = "Average"
      refId       = "A_${cluster}"
      dimensions  = { (local.dimension_cluster) = cluster }
      label       = cluster
      hide        = false
    }
  ]
}
