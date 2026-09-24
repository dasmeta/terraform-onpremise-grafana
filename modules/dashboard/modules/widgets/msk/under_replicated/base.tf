module "base" {
  source = "../../base"

  name = "Under-replicated partitions"
  data_source = {
    uid  = var.datasource_uid
    type = "Cloudwatch"
  }
  coordinates = var.coordinates
  period      = var.period
  region      = var.region

  cloudwatch_targets = flatten([
    for cluster in var.cluster_names : [
      for broker in var.broker_ids : [
        {
          query_mode  = "Metrics"
          region      = var.region
          namespace   = "AWS/Kafka"
          metric_name = "UnderReplicatedPartitions"
          period      = var.period
          statistic   = "Maximum"
          refId       = "A_${cluster}_${broker}"
          dimensions  = { (local.dimension_cluster) = cluster, (local.dimension_broker) = broker }
          label       = "${cluster} broker ${broker}"
          hide        = false
        }
      ]
    ]
  ])
}
