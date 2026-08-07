module "base" {
  source = "../../base"

  name = "Consumer Lag"
  data_source = {
    uid  = var.datasource_uid
    type = "Cloudwatch"
  }
  coordinates = var.coordinates
  period      = var.period
  region      = var.region

  cloudwatch_targets = flatten([
    for cluster in var.cluster_names : length(var.consumer_groups) > 0 ? [
      for group in var.consumer_groups : {
        query_mode  = "Metrics"
        region      = var.region
        namespace   = "AWS/Kafka"
        metric_name = "MaxOffsetLag"
        period      = var.period
        statistic   = "Maximum"
        refId       = "A_${cluster}_${group}"
        dimensions = {
          (local.dimension_cluster)        = cluster
          (local.dimension_consumer_group) = group
        }
        label = "${cluster} ${group}"
        hide  = false
      }
      ] : [{
        query_mode  = "Metrics"
        region      = var.region
        namespace   = "AWS/Kafka"
        metric_name = "EstimatedMaxTimeLag"
        period      = var.period
        statistic   = "Maximum"
        refId       = "A_${cluster}"
        dimensions  = { (local.dimension_cluster) = cluster }
        label       = "${cluster} estimated lag"
        hide        = false
    }]
  ])
}
