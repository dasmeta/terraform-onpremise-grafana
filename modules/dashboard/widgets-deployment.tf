# Pod widgets
module "deployment_replicas_widget" {
  source = "./modules/widgets/deployment/replicas"

  for_each = { for index, item in try(local.widget_config["deployment/replicas"], []) : index => item }

  datasource_uid = try(each.value.datasource_uid, {})
  coordinates    = each.value.coordinates
  period         = each.value.period

  # deployment
  deployment = each.value.deployment
  namespace  = each.value.namespace
}

module "deployment_logs_size_widget" {
  source = "./modules/widgets/deployment/logs-size"

  for_each = { for index, item in try(local.widget_config["deployment/logs-size"], []) : index => item }

  datasource_uid = try(each.value.datasource_uid, {})
  coordinates    = each.value.coordinates
  parser         = try(each.value.parser, "")
  error_filter   = try(each.value.error_filter, "detected_level=\"error\"")
  warn_filter    = try(each.value.warn_filter, "detected_level=\"warn\"")

  # deployment
  deployment = each.value.deployment
  namespace  = each.value.namespace
}

module "deployment_error_logs_widget" {
  source = "./modules/widgets/deployment/error-logs"

  for_each = { for index, item in try(local.widget_config["deployment/error-logs"], []) : index => item }

  datasource_uid = try(each.value.datasource_uid, {})
  coordinates    = each.value.coordinates
  period         = each.value.period
  expr           = try(each.value.expr, "")
  parser         = try(each.value.parser, "logfmt")
  filter         = try(each.value.filter, "detected_level=\"error\"")
  direction      = try(each.value.direction, "backward")
  limit          = try(each.value.limit, 10)

  # deployment
  deployment = each.value.deployment
  namespace  = each.value.namespace
}

module "deployment_warn_logs_widget" {
  source = "./modules/widgets/deployment/warn-logs"

  for_each = { for index, item in try(local.widget_config["deployment/warn-logs"], []) : index => item }

  datasource_uid = try(each.value.datasource_uid, {})
  coordinates    = each.value.coordinates
  period         = each.value.period
  expr           = try(each.value.expr, "")
  parser         = try(each.value.parser, "logfmt")
  filter         = try(each.value.filter, "detected_level=\"warn\"")
  direction      = try(each.value.direction, "backward")
  limit          = try(each.value.limit, 10)

  # deployment
  deployment = each.value.deployment
  namespace  = each.value.namespace
}

module "deployment_latest_logs_widget" {
  source = "./modules/widgets/deployment/latest-logs"

  for_each = { for index, item in try(local.widget_config["deployment/latest-logs"], []) : index => item }

  datasource_uid = try(each.value.datasource_uid, {})
  coordinates    = each.value.coordinates
  period         = each.value.period
  expr           = try(each.value.expr, "")
  parser         = try(each.value.parser, "logfmt")
  filter         = try(each.value.filter, "")
  direction      = try(each.value.direction, "backward")
  limit          = try(each.value.limit, 10)

  # deployment
  deployment = each.value.deployment
  namespace  = each.value.namespace
}
