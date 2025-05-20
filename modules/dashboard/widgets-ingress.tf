# Ingress widgets

module "ingress_connections_widget" {
  source = "./modules/widgets/ingress/connections"

  for_each = { for index, item in try(local.widget_config["ingress/connections"], []) : index => item }

  # data_source = try(each.value.data_source, {})
  datasource_type = try(each.value.datasource_type, null)
  datasource_uid  = try(each.value.datasource_uid, null)
  coordinates     = each.value.coordinates
  period          = each.value.period

  region = each.value.region
}

module "ingress_request_rate_widget" {
  source = "./modules/widgets/ingress/request-rate"

  for_each = { for index, item in try(local.widget_config["ingress/request-rate"], []) : index => item }

  # data_source = try(each.value.data_source, {})
  datasource_type = try(each.value.datasource_type, null)
  datasource_uid  = try(each.value.datasource_uid, null)
  coordinates     = each.value.coordinates
  period          = each.value.period
  by_host         = try(each.value.by_host, false)

  region = each.value.region
}

module "ingress_request_count_widget" {
  source = "./modules/widgets/ingress/request-count"

  for_each = { for index, item in try(local.widget_config["ingress/request-count"], []) : index => item }

  # data_source = try(each.value.data_source, {})
  datasource_type = try(each.value.datasource_type, null)
  datasource_uid  = try(each.value.datasource_uid, null)
  coordinates     = each.value.coordinates
  period          = each.value.period
  by_host         = try(each.value.by_host, false)
  by_path         = try(each.value.by_path, false)
  by_status_path  = try(each.value.by_status_path, false)
  only_5xx        = try(each.value.only_5xx, false)

  region = each.value.region
}

module "ingress_cpu_widget" {
  source = "./modules/widgets/ingress/cpu"

  for_each = { for index, item in try(local.widget_config["ingress/cpu"], []) : index => item }

  # data_source = try(each.value.data_source, {})
  datasource_type = try(each.value.datasource_type, null)
  datasource_uid  = try(each.value.datasource_uid, null)
  coordinates     = each.value.coordinates
  period          = each.value.period

  pod       = each.value.pod
  namespace = each.value.namespace

  region = each.value.region
}

module "ingress_memory_widget" {
  source = "./modules/widgets/ingress/memory"

  for_each = { for index, item in try(local.widget_config["ingress/memory"], []) : index => item }

  # data_source = try(each.value.data_source, {})
  datasource_type = try(each.value.datasource_type, null)
  datasource_uid  = try(each.value.datasource_uid, null)
  coordinates     = each.value.coordinates
  period          = each.value.period

  pod       = each.value.pod
  namespace = each.value.namespace

  region = each.value.region
}

module "ingress_latency_widget" {
  source = "./modules/widgets/ingress/latency"

  for_each = { for index, item in try(local.widget_config["ingress/latency"], []) : index => item }

  # data_source = try(each.value.data_source, {})
  datasource_type = try(each.value.datasource_type, null)
  datasource_uid  = try(each.value.datasource_uid, null)
  coordinates     = each.value.coordinates
  period          = each.value.period
  by_host         = try(each.value.by_host, false)
  acceptable      = try(each.value.acceptable, 1)
  problem         = try(each.value.problem, 2)

  region = each.value.region
}
