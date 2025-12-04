# Redis widgets
module "redis_max_uptime_widget" {
  source = "./modules/widgets/redis/max-uptime"

  for_each = { for index, item in try(local.widget_config["redis/max-uptime"], []) : index => item }

  data_source = each.value.data_source
  coordinates = each.value.coordinates
  period      = try(each.value.period, local.widget_default_values.prometheus.period)
  cluster     = each.value.cluster

  redis_name = each.value.redis_name
  namespace  = try(each.value.namespace, "$namespace")
}

module "redis_memory_widget" {
  source = "./modules/widgets/redis/memory"

  for_each = { for index, item in try(local.widget_config["redis/memory"], []) : index => item }

  data_source = each.value.data_source
  coordinates = each.value.coordinates
  period      = try(each.value.period, local.widget_default_values.prometheus.period)
  cluster     = each.value.cluster

  redis_name = each.value.redis_name
  namespace  = try(each.value.namespace, "$namespace")
}

module "redis_total_memory_widget" {
  source = "./modules/widgets/redis/total-memory"

  for_each = { for index, item in try(local.widget_config["redis/total-memory"], []) : index => item }

  data_source = each.value.data_source
  coordinates = each.value.coordinates
  period      = try(each.value.period, local.widget_default_values.prometheus.period)
  cluster     = each.value.cluster

  redis_name = each.value.redis_name
  namespace  = try(each.value.namespace, "$namespace")
}

module "redis_cpu_widget" {
  source = "./modules/widgets/redis/cpu"

  for_each = { for index, item in try(local.widget_config["redis/cpu"], []) : index => item }

  data_source = each.value.data_source
  coordinates = each.value.coordinates
  period      = try(each.value.period, local.widget_default_values.prometheus.period)
  cluster     = each.value.cluster

  redis_name = each.value.redis_name
  namespace  = try(each.value.namespace, "$namespace")
}

module "redis_hits_misses_widget" {
  source = "./modules/widgets/redis/hits-misses"

  for_each = { for index, item in try(local.widget_config["redis/hits-misses"], []) : index => item }

  data_source = each.value.data_source
  coordinates = each.value.coordinates
  period      = try(each.value.period, local.widget_default_values.prometheus.period)
  cluster     = each.value.cluster

  redis_name = each.value.redis_name
  namespace  = try(each.value.namespace, "$namespace")
}

module "redis_restarts_widget" {
  source = "./modules/widgets/redis/restarts"

  for_each = { for index, item in try(local.widget_config["redis/restarts"], []) : index => item }

  data_source = each.value.data_source
  coordinates = each.value.coordinates
  period      = try(each.value.period, local.widget_default_values.prometheus.period)
  cluster     = each.value.cluster

  redis_pod       = each.value.redis_pod
  redis_namespace = each.value.redis_namespace
}

module "redis_errors_widget" {
  source = "./modules/widgets/redis/errors"

  for_each = { for index, item in try(local.widget_config["redis/errors"], []) : index => item }

  data_source = each.value.data_source
  coordinates = each.value.coordinates
  period      = try(each.value.period, local.widget_default_values.prometheus.period)
  cluster     = each.value.cluster

  redis_name = each.value.redis_name
  namespace  = try(each.value.namespace, "$namespace")
}

module "redis_clients_widget" {
  source = "./modules/widgets/redis/clients"

  for_each = { for index, item in try(local.widget_config["redis/clients"], []) : index => item }

  data_source = each.value.data_source
  coordinates = each.value.coordinates
  period      = try(each.value.period, local.widget_default_values.prometheus.period)
  cluster     = each.value.cluster

  redis_name = each.value.redis_name
  namespace  = try(each.value.namespace, "$namespace")
}

module "redis_connections_widget" {
  source = "./modules/widgets/redis/connections"

  for_each = { for index, item in try(local.widget_config["redis/connections"], []) : index => item }

  data_source = each.value.data_source
  coordinates = each.value.coordinates
  period      = try(each.value.period, local.widget_default_values.prometheus.period)
  cluster     = each.value.cluster

  redis_name = each.value.redis_name
  namespace  = try(each.value.namespace, "$namespace")
}

module "redis_latency_widget" {
  source = "./modules/widgets/redis/latency"

  for_each = { for index, item in try(local.widget_config["redis/latency"], []) : index => item }

  data_source = each.value.data_source
  coordinates = each.value.coordinates
  period      = try(each.value.period, local.widget_default_values.prometheus.period)
  cluster     = each.value.cluster

  redis_name = each.value.redis_name
  namespace  = try(each.value.namespace, "$namespace")
}

module "redis_network_widget" {
  source = "./modules/widgets/redis/network"

  for_each = { for index, item in try(local.widget_config["redis/network"], []) : index => item }

  data_source = each.value.data_source
  coordinates = each.value.coordinates
  period      = try(each.value.period, local.widget_default_values.prometheus.period)
  cluster     = each.value.cluster

  redis_name = each.value.redis_name
  namespace  = try(each.value.namespace, "$namespace")
}

module "redis_replicas_widget" {
  source = "./modules/widgets/redis/replicas"

  for_each = { for index, item in try(local.widget_config["redis/replicas"], []) : index => item }

  data_source = each.value.data_source
  coordinates = each.value.coordinates
  period      = try(each.value.period, local.widget_default_values.prometheus.period)
  cluster     = each.value.cluster

  redis_name = each.value.redis_name
  namespace  = try(each.value.namespace, "$namespace")
}

module "redis_total_commands_widget" {
  source = "./modules/widgets/redis/total-commands"

  for_each = { for index, item in try(local.widget_config["redis/total-commands"], []) : index => item }

  data_source = each.value.data_source
  coordinates = each.value.coordinates
  period      = try(each.value.period, local.widget_default_values.prometheus.period)
  cluster     = each.value.cluster

  redis_name = each.value.redis_name
  namespace  = try(each.value.namespace, "$namespace")
}

module "redis_keys_widget" {
  source = "./modules/widgets/redis/keys"

  for_each = { for index, item in try(local.widget_config["redis/keys"], []) : index => item }

  data_source = each.value.data_source
  coordinates = each.value.coordinates
  period      = try(each.value.period, local.widget_default_values.prometheus.period)
  cluster     = each.value.cluster

  redis_name = each.value.redis_name
  namespace  = try(each.value.namespace, "$namespace")
}

module "redis_expired_evicted_keys_widget" {
  source = "./modules/widgets/redis/expired-evicted-keys"

  for_each = { for index, item in try(local.widget_config["redis/expired-evicted-keys"], []) : index => item }

  data_source = each.value.data_source
  coordinates = each.value.coordinates
  period      = try(each.value.period, local.widget_default_values.prometheus.period)
  cluster     = each.value.cluster

  redis_name = each.value.redis_name
  namespace  = try(each.value.namespace, "$namespace")
}

module "redis_expiring_notexpiring_keys_widget" {
  source = "./modules/widgets/redis/expiring-notexpiring-keys"

  for_each = { for index, item in try(local.widget_config["redis/expiring-notexpiring-keys"], []) : index => item }

  data_source = each.value.data_source
  coordinates = each.value.coordinates
  period      = try(each.value.period, local.widget_default_values.prometheus.period)
  cluster     = each.value.cluster

  redis_name = each.value.redis_name
  namespace  = try(each.value.namespace, "$namespace")
}
