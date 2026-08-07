module "base" {
  source = "../../base"

  name = "Offline Partitions"
  data_source = {
    uid  = var.datasource_uid
    type = "Cloudwatch"
  }
  coordinates = var.coordinates
  period      = var.period
  region      = var.region

  cloudwatch_targets = [
    for cluster in var.cluster_names : {
      query_mode  = "Metrics"
      region      = var.region
      namespace   = "AWS/Kafka"
      metric_name = "OfflinePartitionsCount"
      period      = var.period
      statistic   = "Maximum"
      refId       = "A_${cluster}"
      dimensions  = { (local.dimension_cluster) = cluster }
      label       = cluster
      hide        = false
    }
  ]
}
