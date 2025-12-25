module "base" {
  source = "../../base"

  name = "Active Connections"
  data_source = {
    uid  = var.datasource_uid
    type = "Cloudwatch"
  }
  coordinates = var.coordinates
  period      = var.period
  region      = var.region

  cloudwatch_targets = flatten([
    for cluster_id in var.cache_cluster_ids : [
      {
        query_mode  = "Metrics"
        region      = var.region
        namespace   = "AWS/ElastiCache"
        metric_name = "CurrConnections"
        period      = var.period
        statistic   = "Average"
        refId       = "A_${cluster_id}"
        dimensions  = { CacheClusterId = cluster_id }
        label       = "${cluster_id} Avg"
        hide        = false
      },
      {
        query_mode  = "Metrics"
        region      = var.region
        namespace   = "AWS/ElastiCache"
        metric_name = "CurrConnections"
        period      = var.period
        statistic   = "Maximum"
        refId       = "B_${cluster_id}"
        dimensions  = { CacheClusterId = cluster_id }
        label       = "${cluster_id} Max"
        hide        = false
      }
    ]
  ])
}
