locals {
  lag_series = flatten([
    for cluster in var.cluster_names : [
      for group in var.consumer_groups : length(var.topics) > 0 ? [
        for topic in var.topics : {
          cluster = cluster
          group   = group
          topic   = topic
        }
        ] : [{
          cluster = cluster
          group   = group
          topic   = null
      }]
    ]
  ])
}

module "base" {
  source = "../../base"

  name = "Consumer lag (max and sum)"
  data_source = {
    uid  = var.datasource_uid
    type = "Cloudwatch"
  }
  coordinates = var.coordinates
  period      = var.period
  region      = var.region

  cloudwatch_targets = flatten([
    for item in local.lag_series : [
      {
        query_mode  = "Metrics"
        region      = var.region
        namespace   = "AWS/Kafka"
        metric_name = "MaxOffsetLag"
        period      = var.period
        statistic   = "Maximum"
        refId       = replace("max_${item.cluster}_${item.group}_${coalesce(item.topic, "all")}", "/[^A-Za-z0-9_]/", "_")
        dimensions = merge(
          {
            (local.dimension_cluster)        = item.cluster
            (local.dimension_consumer_group) = item.group
          },
          item.topic != null ? { (local.dimension_topic) = item.topic } : {}
        )
        label = "${item.cluster} ${item.group}${item.topic != null ? " ${item.topic}" : ""} max"
        hide  = false
      },
      {
        query_mode  = "Metrics"
        region      = var.region
        namespace   = "AWS/Kafka"
        metric_name = "SumOffsetLag"
        period      = var.period
        statistic   = "Maximum"
        refId       = replace("sum_${item.cluster}_${item.group}_${coalesce(item.topic, "all")}", "/[^A-Za-z0-9_]/", "_")
        dimensions = merge(
          {
            (local.dimension_cluster)        = item.cluster
            (local.dimension_consumer_group) = item.group
          },
          item.topic != null ? { (local.dimension_topic) = item.topic } : {}
        )
        label = "${item.cluster} ${item.group}${item.topic != null ? " ${item.topic}" : ""} sum"
        hide  = false
      }
    ]
  ])
}
