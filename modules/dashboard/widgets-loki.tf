module "deployment_logs_size_widget" {
  source = "./modules/widgets/loki/logs-size"

  for_each = { for index, item in try(local.widget_config["deployment/logs-size"], []) : index => item }

  datasource_uid = try(each.value.datasource_uid, local.widget_default_values.loki.datasource_uid)
  coordinates    = each.value.coordinates
  parser         = try(each.value.parser, "")
  error_filter   = try(each.value.error_filter, local.widget_default_values.loki.error_filter)
  warn_filter    = try(each.value.warn_filter, local.widget_default_values.loki.warn_filter)
  period         = try(each.value.period, local.widget_default_values.loki.period)

  # deployment
  deployment = each.value.deployment
  namespace  = each.value.namespace
}

module "deployment_error_logs_widget" {
  source = "./modules/widgets/loki/error-logs"

  for_each = { for index, item in try(local.widget_config["deployment/error-logs"], []) : index => item }

  datasource_uid = try(each.value.datasource_uid, local.widget_default_values.loki.datasource_uid)
  coordinates    = each.value.coordinates
  period         = try(each.value.period, local.widget_default_values.loki.period)
  expr           = try(each.value.expr, "")
  parser         = try(each.value.parser, local.widget_default_values.loki.parser)
  filter         = try(each.value.filter, local.widget_default_values.loki.error_filter)
  direction      = try(each.value.direction, local.widget_default_values.loki.direction)
  limit          = try(each.value.limit, local.widget_default_values.loki.limit)

  # deployment
  deployment = each.value.deployment
  namespace  = each.value.namespace
}

module "deployment_warn_logs_widget" {
  source = "./modules/widgets/loki/warn-logs"

  for_each = { for index, item in try(local.widget_config["deployment/warn-logs"], []) : index => item }

  datasource_uid = try(each.value.datasource_uid, local.widget_default_values.loki.datasource_uid)
  coordinates    = each.value.coordinates
  period         = try(each.value.period, local.widget_default_values.loki.period)
  expr           = try(each.value.expr, "")
  parser         = try(each.value.parser, local.widget_default_values.loki.parser)
  filter         = try(each.value.filter, local.widget_default_values.loki.error_filter)
  direction      = try(each.value.direction, local.widget_default_values.loki.direction)
  limit          = try(each.value.limit, local.widget_default_values.loki.limit)

  # deployment
  deployment = each.value.deployment
  namespace  = each.value.namespace
}

module "deployment_latest_logs_widget" {
  source = "./modules/widgets/loki/latest-logs"

  for_each = { for index, item in try(local.widget_config["deployment/latest-logs"], []) : index => item }

  datasource_uid = try(each.value.datasource_uid, local.widget_default_values.loki.datasource_uid)
  coordinates    = each.value.coordinates
  period         = try(each.value.period, local.widget_default_values.loki.period)
  expr           = try(each.value.expr, "")
  parser         = try(each.value.parser, local.widget_default_values.loki.parser)
  filter         = try(each.value.filter, "")
  direction      = try(each.value.direction, local.widget_default_values.loki.direction)
  limit          = try(each.value.limit, local.widget_default_values.loki.limit)

  # deployment
  deployment = each.value.deployment
  namespace  = each.value.namespace
}

# Logs widgets
module "logs_count_widget" {
  source = "./modules/widgets/loki/count"

  for_each = { for index, item in try(local.widget_config["logs/count"], []) : index => item }

  data_source = each.value.data_source
  coordinates = each.value.coordinates
  period      = try(each.value.period, local.widget_default_values.prometheus.period)

  aggregated_metric = each.value.aggregated_metric

  account_id        = each.value.account_id
  region            = each.value.region
  anomaly_detection = each.value.anomaly_detection
  anomaly_deviation = each.value.anomaly_deviation
}

module "logs_error_rate_widget" {
  source = "./modules/widgets/loki/error-rate"

  for_each = { for index, item in try(local.widget_config["logs/error-rate"], []) : index => item }

  data_source = each.value.data_source
  coordinates = each.value.coordinates
  period      = try(each.value.period, local.widget_default_values.prometheus.period)

  aggregated_metric = each.value.aggregated_metric

  account_id        = each.value.account_id
  region            = each.value.region
  anomaly_detection = each.value.anomaly_detection
  anomaly_deviation = each.value.anomaly_deviation
}

module "logs_warning_rate_widget" {
  source = "./modules/widgets/loki/warning-rate"

  for_each = { for index, item in try(local.widget_config["logs/warning-rate"], []) : index => item }

  data_source = each.value.data_source
  coordinates = each.value.coordinates
  period      = try(each.value.period, local.widget_default_values.prometheus.period)

  aggregated_metric = each.value.aggregated_metric

  account_id        = each.value.account_id
  region            = each.value.region
  anomaly_detection = each.value.anomaly_detection
  anomaly_deviation = each.value.anomaly_deviation
}
