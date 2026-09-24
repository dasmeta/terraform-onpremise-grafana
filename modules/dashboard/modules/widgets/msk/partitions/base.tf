module "base" {
  source = "../../base"

  name = "Global Partition Count"
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
      metric_name = "GlobalPartitionCount"
      period      = var.period
      statistic   = "Average"
      refId       = "A_${cluster}"
      dimensions  = { (local.dimension_cluster) = cluster }
      label       = cluster
      hide        = false
    }
  ]
}
