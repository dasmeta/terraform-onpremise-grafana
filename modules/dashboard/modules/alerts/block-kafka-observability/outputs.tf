locals {
  matchers = compact([
    var.namespace != "" ? "namespace=\"${var.namespace}\"" : "",
    var.cluster_label != "" && var.cluster != "" ? "${var.cluster_label}=\"${var.cluster}\"" : "",
    var.extra_filters != "" ? var.extra_filters : "",
  ])
  selector = join(",", local.matchers)

  scrape_matchers = compact([
    var.namespace != "" ? "namespace=\"${var.namespace}\"" : "",
    var.cluster_label != "" && var.cluster != "" ? "${var.cluster_label}=\"${var.cluster}\"" : "",
    var.exporter_scrape_filters != "" ? var.exporter_scrape_filters : var.extra_filters,
  ])
  scrape_selector = join(",", local.scrape_matchers)

  critical_re    = join("|", var.critical_consumer_groups)
  idle_re        = join("|", var.idle_consumer_groups)
  stopped_re     = join("|", var.stopped_connectors)
  group_filter   = length(var.critical_consumer_groups) > 0 ? ",consumergroup=~\"${local.critical_re}\"" : ""
  idle_filter    = length(var.idle_consumer_groups) > 0 ? ",consumergroup!~\"${local.idle_re}\"" : ""
  stopped_filter = length(var.stopped_connectors) > 0 ? ",connector!~\"${local.stopped_re}\"" : ""

  pending_period = coalesce(try(var.alerts.pending_period, null), var.pending_period, try(var.defaults.pending_period, null), "5m")
  group_name     = coalesce(try(var.defaults.group, null), "Kafka observability ${var.namespace}")

  default_labels = merge(
    { priority = "P1", severity = "critical" },
    try(var.defaults.labels, {}),
    try(var.alerts.labels, {})
  )

  link_annotations = merge(
    var.dashboard_url != "" ? { dashboard_url = var.dashboard_url } : {},
    var.runbook_url != "" ? { runbook = var.runbook_url } : {},
    try(var.alerts.annotations, {})
  )

  consumer_group_lag_enabled = length(var.critical_consumer_groups) > 0 && coalesce(try(var.alerts.consumer_group_lag.enabled, null), try(var.alerts.enabled, true), true)
  connector_failed_enabled   = coalesce(try(var.alerts.connector_failed.enabled, null), try(var.alerts.enabled, true), true)
  task_failed_enabled        = coalesce(try(var.alerts.task_failed.enabled, null), try(var.alerts.enabled, true), true)
  connect_rest_down_enabled  = coalesce(try(var.alerts.connect_rest_down.enabled, null), try(var.alerts.enabled, true), true)
  exporter_scrape_enabled    = coalesce(try(var.alerts.exporter_scrape.enabled, null), false)

  consumer_group_lag_expr = chomp(<<-EOT
(
  sum by (consumergroup) (increase(kafka_consumergroup_lag{${local.selector}${local.group_filter}${local.idle_filter}}[${var.lag_growth_window}]))
) > ${var.lag_threshold}
and
(
  sum by (consumergroup) (kafka_consumergroup_members{${local.selector}${local.group_filter}${local.idle_filter}})
) == 0
EOT
  )

  connector_failed_expr = "sum by (connector) (kafka_connect_connector_state{${local.selector},state=\"${var.failed_state}\"${local.stopped_filter}}) > 0"
  task_failed_expr      = "sum by (connector, task) (kafka_connect_task_state{${local.selector},state=\"${var.failed_state}\"${local.stopped_filter}}) > 0"
  connect_rest_expr     = "sum(kafka_connect_rest_up{${local.selector}}) == 0"
  exporter_scrape_expr  = "sum by (job) (up{${local.scrape_selector}}) == 0"
}

output "alert_rules" {
  description = "Grafana-managed Kafka observability alert rules"
  value = concat(
    local.consumer_group_lag_enabled ? [
      {
        name           = "Kafka critical consumer group in ${var.namespace} has no members and growing lag"
        summary        = "Consumer group {{ $labels.consumergroup }} has zero members and lag increased"
        group          = coalesce(try(var.alerts.consumer_group_lag.group, null), local.group_name)
        datasource     = var.datasource
        no_data_state  = coalesce(try(var.alerts.consumer_group_lag.no_data_state, null), try(var.defaults.no_data_state, null), "NoData")
        exec_err_state = coalesce(try(var.alerts.consumer_group_lag.exec_err_state, null), try(var.defaults.exec_err_state, null), "Error")
        expr           = local.consumer_group_lag_expr
        pending_period = coalesce(try(var.alerts.consumer_group_lag.pending_period, null), local.pending_period)
        function       = "last"
        equation       = "gt"
        threshold      = 0
        filters        = {}
        labels         = merge(local.default_labels, try(var.alerts.consumer_group_lag.labels, {}))
        annotations = merge({
          summary      = "Consumer group {{ $labels.consumergroup }} has zero members and lag increased"
          description  = "A configured critical Kafka consumer group has no active members and kafka_consumergroup_lag increased during ${var.lag_growth_window}. Intentionally idle groups are excluded."
          component    = "kafka"
          metric       = "kafka_consumergroup_lag"
          issue_phrase = "idle consumer group with growing lag"
          impact       = "Messages may accumulate without being processed"
          threshold    = tostring(var.lag_threshold)
        }, local.link_annotations, try(var.alerts.consumer_group_lag.annotations, {}))
        settings_mode        = "replaceNN"
        settings_replaceWith = 0
      }
    ] : [],
    local.connector_failed_enabled ? [
      {
        name           = "Kafka Connect connector in ${var.namespace} is FAILED"
        summary        = "Kafka Connect connector {{ $labels.connector }} is in ${var.failed_state} state"
        group          = coalesce(try(var.alerts.connector_failed.group, null), local.group_name)
        datasource     = var.datasource
        no_data_state  = coalesce(try(var.alerts.connector_failed.no_data_state, null), try(var.defaults.no_data_state, null), "NoData")
        exec_err_state = coalesce(try(var.alerts.connector_failed.exec_err_state, null), try(var.defaults.exec_err_state, null), "Error")
        expr           = local.connector_failed_expr
        pending_period = coalesce(try(var.alerts.connector_failed.pending_period, null), local.pending_period)
        function       = "last"
        equation       = "gt"
        threshold      = 0
        filters        = {}
        labels         = merge(local.default_labels, try(var.alerts.connector_failed.labels, {}))
        annotations = merge({
          summary      = "Kafka Connect connector {{ $labels.connector }} is in ${var.failed_state} state"
          description  = "kafka_connect_connector_state reports ${var.failed_state} for connector {{ $labels.connector }}. Intentionally stopped connectors are excluded."
          component    = "kafka-connect"
          metric       = "kafka_connect_connector_state"
          issue_phrase = "connector failed"
          impact       = "Connector work is not running"
        }, local.link_annotations, try(var.alerts.connector_failed.annotations, {}))
        settings_mode        = "replaceNN"
        settings_replaceWith = 0
      }
    ] : [],
    local.task_failed_enabled ? [
      {
        name           = "Kafka Connect task in ${var.namespace} is FAILED"
        summary        = "Kafka Connect task {{ $labels.connector }}/{{ $labels.task }} is in ${var.failed_state} state"
        group          = coalesce(try(var.alerts.task_failed.group, null), local.group_name)
        datasource     = var.datasource
        no_data_state  = coalesce(try(var.alerts.task_failed.no_data_state, null), try(var.defaults.no_data_state, null), "NoData")
        exec_err_state = coalesce(try(var.alerts.task_failed.exec_err_state, null), try(var.defaults.exec_err_state, null), "Error")
        expr           = local.task_failed_expr
        pending_period = coalesce(try(var.alerts.task_failed.pending_period, null), local.pending_period)
        function       = "last"
        equation       = "gt"
        threshold      = 0
        filters        = {}
        labels         = merge(local.default_labels, try(var.alerts.task_failed.labels, {}))
        annotations = merge({
          summary      = "Kafka Connect task {{ $labels.connector }}/{{ $labels.task }} is in ${var.failed_state} state"
          description  = "kafka_connect_task_state reports ${var.failed_state} for connector {{ $labels.connector }} task {{ $labels.task }}. Intentionally stopped connectors are excluded."
          component    = "kafka-connect"
          metric       = "kafka_connect_task_state"
          issue_phrase = "connector task failed"
          impact       = "A connector task is not processing data"
        }, local.link_annotations, try(var.alerts.task_failed.annotations, {}))
        settings_mode        = "replaceNN"
        settings_replaceWith = 0
      }
    ] : [],
    local.connect_rest_down_enabled ? [
      {
        name           = "Kafka Connect REST endpoint in ${var.namespace} is unavailable"
        summary        = "Kafka Connect REST endpoint is down"
        group          = coalesce(try(var.alerts.connect_rest_down.group, null), local.group_name)
        datasource     = var.datasource
        no_data_state  = coalesce(try(var.alerts.connect_rest_down.no_data_state, null), try(var.defaults.no_data_state, null), "NoData")
        exec_err_state = coalesce(try(var.alerts.connect_rest_down.exec_err_state, null), try(var.defaults.exec_err_state, null), "Error")
        expr           = local.connect_rest_expr
        pending_period = coalesce(try(var.alerts.connect_rest_down.pending_period, null), local.pending_period)
        function       = "last"
        equation       = "gt"
        threshold      = 0
        filters        = {}
        labels         = merge(local.default_labels, try(var.alerts.connect_rest_down.labels, {}))
        annotations = merge({
          summary      = "Kafka Connect REST endpoint is down"
          description  = "kafka_connect_rest_up is 0 in namespace ${var.namespace}. Connector management and status collection may be unavailable."
          component    = "kafka-connect"
          metric       = "kafka_connect_rest_up"
          issue_phrase = "connect REST unavailable"
          impact       = "Kafka Connect cannot be queried or managed through its REST API"
        }, local.link_annotations, try(var.alerts.connect_rest_down.annotations, {}))
        settings_mode        = "replaceNN"
        settings_replaceWith = 0
      }
    ] : [],
    local.exporter_scrape_enabled ? [
      {
        name           = "Kafka exporter scrape failed in ${var.namespace}"
        summary        = "Kafka observability exporter {{ $labels.job }} is down"
        group          = coalesce(try(var.alerts.exporter_scrape.group, null), local.group_name)
        datasource     = var.datasource
        no_data_state  = coalesce(try(var.alerts.exporter_scrape.no_data_state, null), try(var.defaults.no_data_state, null), "NoData")
        exec_err_state = coalesce(try(var.alerts.exporter_scrape.exec_err_state, null), try(var.defaults.exec_err_state, null), "Error")
        expr           = local.exporter_scrape_expr
        pending_period = coalesce(try(var.alerts.exporter_scrape.pending_period, null), local.pending_period)
        function       = "last"
        equation       = "gt"
        threshold      = 0
        filters        = {}
        labels         = merge({ priority = "P2", severity = "warning" }, try(var.defaults.labels, {}), try(var.alerts.labels, {}), try(var.alerts.exporter_scrape.labels, {}))
        annotations = merge({
          summary      = "Kafka observability exporter {{ $labels.job }} is down"
          description  = "Prometheus scrape health (up) is 0 for the configured Kafka exporter selector in namespace ${var.namespace}."
          component    = "kafka"
          metric       = "up"
          issue_phrase = "exporter scrape failure"
          impact       = "Kafka consumer-group or Connect metrics may be missing"
        }, local.link_annotations, try(var.alerts.exporter_scrape.annotations, {}))
        settings_mode        = "replaceNN"
        settings_replaceWith = 0
      }
    ] : [],
  )
}
