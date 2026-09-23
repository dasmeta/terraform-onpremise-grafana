locals {
  offline_partitions_enabled = coalesce(
    try(var.alerts.offline_partitions.enabled, null),
    try(var.alerts.enabled, false),
    false
  )

  consumer_lag_enabled = length(var.consumer_groups) > 0 && coalesce(
    try(var.alerts.consumer_lag.enabled, null),
    try(var.alerts.enabled, false),
    false
  )

  default_labels = merge(
    { priority = "P2", severity = "warning" },
    try(var.defaults.labels, {}),
    try(var.alerts.labels, {})
  )

  lag_threshold = coalesce(try(var.alerts.consumer_lag.threshold, null), var.lag_threshold)
  lag_pending   = coalesce(try(var.alerts.consumer_lag.pending_period, null), try(var.defaults.pending_period, null), "15m")

  lag_targets = flatten([
    for cluster in var.cluster_names : [
      for group in var.consumer_groups : length(var.topics) > 0 ? [
        for topic in var.topics : {
          cluster     = cluster
          group       = group
          topic       = topic
          match_exact = true
        }
        ] : [{
          cluster     = cluster
          group       = group
          topic       = null
          match_exact = false
      }]
    ]
  ])
}

output "alert_rules" {
  value = concat(
    local.offline_partitions_enabled ? flatten([
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
          settings_mode        = "Strict"
          settings_replaceWith = 0
          cloudwatch_query = {
            namespace   = "AWS/Kafka"
            metric_name = "OfflinePartitionsCount"
            dimensions  = { "Cluster Name" = cluster }
            statistic   = "Maximum"
            period      = "300"
            region      = var.region
            match_exact = true
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
    ]) : [],
    local.consumer_lag_enabled ? [
      for item in local.lag_targets : {
        name                 = item.topic != null ? "MSK consumer group `${item.group}` topic `${item.topic}` lag is high on `${item.cluster}`" : "MSK consumer group `${item.group}` lag is high on `${item.cluster}`"
        group                = coalesce(try(var.alerts.consumer_lag.group, null), try(var.defaults.group, null), "MSK ${item.cluster}")
        datasource           = var.datasource
        datasource_type      = "cloudwatch"
        no_data_state        = coalesce(try(var.alerts.consumer_lag.no_data_state, null), try(var.defaults.no_data_state, null), "NoData")
        exec_err_state       = coalesce(try(var.alerts.consumer_lag.exec_err_state, null), try(var.defaults.exec_err_state, null), "Error")
        pending_period       = local.lag_pending
        function             = "last"
        equation             = "gt"
        threshold            = local.lag_threshold
        interval_ms          = 1000
        settings_mode        = "Strict"
        settings_replaceWith = 0
        cloudwatch_query = {
          namespace   = "AWS/Kafka"
          metric_name = "MaxOffsetLag"
          dimensions = merge(
            {
              "Cluster Name"   = item.cluster
              "Consumer Group" = item.group
            },
            item.topic != null ? { Topic = item.topic } : {}
          )
          statistic   = "Maximum"
          period      = "300"
          region      = var.region
          match_exact = item.match_exact
        }
        labels = merge(local.default_labels, try(var.alerts.consumer_lag.labels, {}))
        annotations = merge(
          {
            component    = "kafka"
            metric       = "MaxOffsetLag"
            issue_phrase = "sustained consumer lag"
            impact       = "Consumers are falling behind producers. Native MSK lag does not report exact active-member count."
            threshold    = tostring(local.lag_threshold)
          },
          try(var.alerts.annotations, {}),
          try(var.alerts.consumer_lag.annotations, {})
        )
      }
    ] : [],
  )
}
