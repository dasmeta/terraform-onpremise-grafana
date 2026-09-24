locals {
  offline_partitions_enabled = coalesce(
    try(var.alerts.offline_partitions.enabled, null),
    try(var.alerts.enabled, false),
    false
  )

  default_labels = merge(
    { priority = "P2", severity = "warning" },
    try(var.defaults.labels, {}),
    try(var.alerts.labels, {})
  )
}

output "alert_rules" {
  value = local.offline_partitions_enabled ? flatten([
    for cluster in var.cluster_names : [
      {
        name                 = "MSK cluster `${cluster}` has offline partitions"
        group                = coalesce(try(var.alerts.offline_partitions.group, null), try(var.defaults.group, null), "MSK ${cluster}")
        datasource           = var.datasource
        datasource_type      = "cloudwatch"
        no_data_state        = coalesce(try(var.alerts.offline_partitions.no_data_state, null), try(var.defaults.no_data_state, null), "NoData")
        exec_err_state       = coalesce(try(var.alerts.offline_partitions.exec_err_state, null), try(var.defaults.exec_err_state, null), "Error")
        pending_period       = coalesce(try(var.alerts.offline_partitions.pending_period, null), try(var.defaults.pending_period, null), "5m")
        function             = "last"
        equation             = "gt"
        threshold            = try(var.alerts.offline_partitions.threshold, 0)
        interval_ms          = 1000
        settings_mode        = "replaceNN"
        settings_replaceWith = 0
        cloudwatch_query = {
          namespace   = "AWS/Kafka"
          metric_name = "OfflinePartitionsCount"
          dimensions  = { "Cluster Name" = cluster }
          statistic   = "Maximum"
          period      = "300"
          region      = var.region
        }
        labels = merge(local.default_labels, try(var.alerts.offline_partitions.labels, {}))
        annotations = merge(
          {
            component    = "kafka"
            metric       = "offline-partitions"
            issue_phrase = "MSK partition outage"
            impact       = "Message processing may be blocked for affected partitions"
          },
          try(var.alerts.annotations, {}),
          try(var.alerts.offline_partitions.annotations, {})
        )
      }
    ]
  ]) : []
}
