module "selector" {
  source = "../../widgets/kafka/selector"

  namespace     = var.namespace
  extra_filters = var.extra_filters
  cluster_label = var.cluster_label
  cluster       = var.cluster
}

module "scrape_selector" {
  source = "../../widgets/kafka/selector"

  namespace     = var.namespace
  extra_filters = var.exporter_scrape_filters != "" ? var.exporter_scrape_filters : var.extra_filters
  cluster_label = var.cluster_label
  cluster       = var.cluster
}

locals {
  selector        = module.selector.selector
  scrape_selector = module.scrape_selector.selector
  stopped_re      = join("|", var.stopped_connectors)
  stopped_filter  = length(var.stopped_connectors) > 0 ? ",connector!~\"${local.stopped_re}\"" : ""
  failed_selector = "{${join(",", concat(module.selector.matchers, ["state=\"${var.failed_state}\""]))}${local.stopped_filter}}"

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

  connector_failed_enabled  = coalesce(try(var.alerts.connector_failed.enabled, null), try(var.alerts.enabled, false), false)
  task_failed_enabled       = coalesce(try(var.alerts.task_failed.enabled, null), try(var.alerts.enabled, false), false)
  connect_rest_down_enabled = coalesce(try(var.alerts.connect_rest_down.enabled, null), try(var.alerts.enabled, false), false)
  exporter_scrape_enabled   = coalesce(try(var.alerts.exporter_scrape.enabled, null), try(var.alerts.enabled, false), false)

  connector_failed_expr = "sum by (connector) (kafka_connect_connector_state${local.failed_selector}) > 0"
  task_failed_expr      = "sum by (connector, task) (kafka_connect_task_state${local.failed_selector}) > 0"
  # == bool 0 returns 1 when down so Grafana reduce last() > 0 can fire. Bare == 0 keeps value 0 and never matches gt 0.
  connect_rest_expr    = "sum(kafka_connect_rest_up${local.selector}) == bool 0"
  exporter_scrape_expr = "(sum by (job) (up${local.scrape_selector}) == bool 0) or absent(kafka_connect_rest_up${local.selector})"
}

output "alert_rules" {
  description = "Grafana-managed Kafka Connect status-exporter alert rules"
  value = concat(
    local.connector_failed_enabled ? [
      {
        name           = "Kafka Connect connector in ${var.namespace} is ${var.failed_state}"
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
          description  = "kafka-connect-status-exporter kafka_connect_connector_state reports ${var.failed_state} for connector {{ $labels.connector }}. Intentionally stopped or paused connectors can be excluded with stopped_connectors."
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
        name           = "Kafka Connect task in ${var.namespace} is ${var.failed_state}"
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
          description  = "kafka-connect-status-exporter kafka_connect_task_state reports ${var.failed_state} for connector {{ $labels.connector }} task {{ $labels.task }}. Intentionally stopped or paused connectors can be excluded with stopped_connectors."
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
        name           = "Kafka Connect status exporter scrape failed in ${var.namespace}"
        summary        = "kafka-connect-status-exporter {{ $labels.job }} is down or kafka_connect_rest_up is missing"
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
          summary      = "kafka-connect-status-exporter {{ $labels.job }} is down or expected metrics are missing"
          description  = "Prometheus/VictoriaMetrics scrape health is 0 or kafka_connect_rest_up is absent for the configured kafka-connect-status-exporter selector in namespace ${var.namespace}."
          component    = "kafka-connect"
          metric       = "up"
          issue_phrase = "exporter scrape failure"
          impact       = "Kafka Connect status metrics may be missing"
        }, local.link_annotations, try(var.alerts.exporter_scrape.annotations, {}))
        settings_mode        = "replaceNN"
        settings_replaceWith = 0
      }
    ] : [],
  )
}

output "connector_failed_expr" {
  description = "Rendered PromQL for connector failed-state alerts"
  value       = local.connector_failed_expr
}

output "task_failed_expr" {
  description = "Rendered PromQL for task failed-state alerts"
  value       = local.task_failed_expr
}

output "connect_rest_expr" {
  description = "Rendered PromQL for Kafka Connect REST down alerts"
  value       = local.connect_rest_expr
}

output "exporter_scrape_expr" {
  description = "Rendered PromQL for Connect exporter scrape alerts"
  value       = local.exporter_scrape_expr
}
