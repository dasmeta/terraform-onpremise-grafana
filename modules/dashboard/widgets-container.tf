# Container widgets
module "container_cpu_widget" {
  source = "./modules/widgets/container/cpu"

  for_each = { for index, item in try(local.widget_config["container/cpu"], []) : index => item }

  data_source = try(each.value.data_source, {})
  coordinates = each.value.coordinates
  period      = each.value.period

  # container
  container = each.value.container
  namespace = each.value.namespace
  by_pod    = try(each.value.by_pod, false)
}

module "container_memory_widget" {
  source = "./modules/widgets/container/memory"

  for_each = { for index, item in try(local.widget_config["container/memory"], []) : index => item }

  data_source = try(each.value.data_source, {})
  coordinates = each.value.coordinates
  period      = each.value.period

  # container
  container = each.value.container
  namespace = each.value.namespace
}

module "container_network_widget" {
  source = "./modules/widgets/container/network"

  for_each = { for index, item in try(local.widget_config["container/network"], []) : index => item }

  data_source = try(each.value.data_source, {})
  coordinates = each.value.coordinates
  period      = each.value.period

  # container
  container = each.value.container
  namespace = each.value.namespace
  host      = try(each.value.host, null)
}

module "container_replicas_widget" {
  source = "./modules/widgets/container/replicas"

  for_each = { for index, item in try(local.widget_config["container/replicas"], []) : index => item }

  data_source = try(each.value.data_source, {})
  coordinates = each.value.coordinates
  period      = each.value.period

  # container
  container = each.value.container
  namespace = each.value.namespace
}

module "container_restarts_widget" {
  source = "./modules/widgets/container/restarts"

  for_each = { for index, item in try(local.widget_config["container/restarts"], []) : index => item }

  data_source = try(each.value.data_source, {})
  coordinates = each.value.coordinates
  period      = each.value.period

  # container
  container = each.value.container
  namespace = each.value.namespace
}

module "container_request_count_widget" {
  source = "./modules/widgets/container/request-count"

  for_each = { for index, item in try(local.widget_config["container/request-count"], []) : index => item }

  data_source = try(each.value.data_source, {})
  coordinates = each.value.coordinates
  period      = each.value.period

  # container
  host              = each.value.host
  target_group_name = try(each.value.target_group_name, null)
  only_5xx          = try(each.value.only_5xx, false)
}

module "container_response_time_widget" {
  source = "./modules/widgets/container/response-time"

  for_each = { for index, item in try(local.widget_config["container/response-time"], []) : index => item }

  data_source = try(each.value.data_source, {})
  coordinates = each.value.coordinates
  period      = each.value.period
  acceptable  = try(each.value.acceptable, 1)
  problem     = try(each.value.problem, 2)

  # container
  host = each.value.host
}

module "container_network_traffic_widget" {
  source = "./modules/widgets/container/network-traffic"

  for_each = { for index, item in try(local.widget_config["container/network-traffic"], []) : index => item }

  data_source = try(each.value.data_source, {})
  coordinates = each.value.coordinates
  period      = each.value.period

  pod = each.value.pod
}

module "container_network_transmit_widget" {
  source = "./modules/widgets/container/network-transmit"

  for_each = { for index, item in try(local.widget_config["container/network-transmit"], []) : index => item }

  data_source = try(each.value.data_source, {})
  coordinates = each.value.coordinates
  period      = each.value.period

  pod = each.value.pod
}
