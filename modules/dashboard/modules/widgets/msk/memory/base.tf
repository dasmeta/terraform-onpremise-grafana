module "base" {
  source = "../../base"

  name = "Memory Used"
  data_source = {
    uid  = var.datasource_uid
    type = "Cloudwatch"
  }
  coordinates = var.coordinates
  period      = var.period
  region      = var.region
  unit        = "bytes"

  cloudwatch_targets = flatten([
    for cluster in var.cluster_names : [
      for broker in var.broker_ids : [
        {
          query_mode  = "Metrics"
          region      = var.region
          namespace   = "AWS/Kafka"
          metric_name = "MemoryUsed"
          period      = var.period
          statistic   = "Average"
          refId       = "A_${cluster}_${broker}"
          dimensions  = { (local.dimension_cluster) = cluster, (local.dimension_broker) = broker }
          label       = "${cluster} broker ${broker}"
          hide        = false
        }
      ]
    ]
  ])
}
