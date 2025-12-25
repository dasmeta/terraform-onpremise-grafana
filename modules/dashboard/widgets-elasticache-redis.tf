# ElastiCache Redis widgets

module "elasticache_redis_cpu_widget" {
  source = "./modules/widgets/elasticache_redis/cpu"

  for_each = { for index, item in try(local.widget_config["elasticache_redis/cpu"], []) : index => item }

  coordinates       = each.value.coordinates
  cache_cluster_ids = try(each.value.cache_cluster_ids, [])
  region            = try(each.value.region, local.widget_default_values.cloudwatch.region)
  period            = try(each.value.period, local.widget_default_values.cloudwatch.period)
  datasource_uid    = try(each.value.datasource_uid, local.widget_default_values.cloudwatch.datasource_uid)
}

module "elasticache_redis_memory_widget" {
  source = "./modules/widgets/elasticache_redis/memory"

  for_each = { for index, item in try(local.widget_config["elasticache_redis/memory"], []) : index => item }

  coordinates       = each.value.coordinates
  cache_cluster_ids = try(each.value.cache_cluster_ids, [])
  region            = try(each.value.region, local.widget_default_values.cloudwatch.region)
  period            = try(each.value.period, local.widget_default_values.cloudwatch.period)
  datasource_uid    = try(each.value.datasource_uid, local.widget_default_values.cloudwatch.datasource_uid)
}

module "elasticache_redis_capacity_widget" {
  source = "./modules/widgets/elasticache_redis/capacity"

  for_each = { for index, item in try(local.widget_config["elasticache_redis/capacity"], []) : index => item }

  coordinates       = each.value.coordinates
  cache_cluster_ids = try(each.value.cache_cluster_ids, [])
  region            = try(each.value.region, local.widget_default_values.cloudwatch.region)
  period            = try(each.value.period, local.widget_default_values.cloudwatch.period)
  datasource_uid    = try(each.value.datasource_uid, local.widget_default_values.cloudwatch.datasource_uid)
}

module "elasticache_redis_latency_widget" {
  source = "./modules/widgets/elasticache_redis/latency"

  for_each = { for index, item in try(local.widget_config["elasticache_redis/latency"], []) : index => item }

  coordinates       = each.value.coordinates
  cache_cluster_ids = try(each.value.cache_cluster_ids, [])
  region            = try(each.value.region, local.widget_default_values.cloudwatch.region)
  period            = try(each.value.period, local.widget_default_values.cloudwatch.period)
  datasource_uid    = try(each.value.datasource_uid, local.widget_default_values.cloudwatch.datasource_uid)
}

module "elasticache_redis_connections_widget" {
  source = "./modules/widgets/elasticache_redis/connections"

  for_each = { for index, item in try(local.widget_config["elasticache_redis/connections"], []) : index => item }

  coordinates       = each.value.coordinates
  cache_cluster_ids = try(each.value.cache_cluster_ids, [])
  region            = try(each.value.region, local.widget_default_values.cloudwatch.region)
  period            = try(each.value.period, local.widget_default_values.cloudwatch.period)
  datasource_uid    = try(each.value.datasource_uid, local.widget_default_values.cloudwatch.datasource_uid)
}

module "elasticache_redis_new_connections_widget" {
  source = "./modules/widgets/elasticache_redis/new_connections"

  for_each = { for index, item in try(local.widget_config["elasticache_redis/new_connections"], []) : index => item }

  coordinates       = each.value.coordinates
  cache_cluster_ids = try(each.value.cache_cluster_ids, [])
  region            = try(each.value.region, local.widget_default_values.cloudwatch.region)
  period            = try(each.value.period, local.widget_default_values.cloudwatch.period)
  datasource_uid    = try(each.value.datasource_uid, local.widget_default_values.cloudwatch.datasource_uid)
}

module "elasticache_redis_hit_rate_widget" {
  source = "./modules/widgets/elasticache_redis/hit_rate"

  for_each = { for index, item in try(local.widget_config["elasticache_redis/hit_rate"], []) : index => item }

  coordinates       = each.value.coordinates
  cache_cluster_ids = try(each.value.cache_cluster_ids, [])
  region            = try(each.value.region, local.widget_default_values.cloudwatch.region)
  period            = try(each.value.period, local.widget_default_values.cloudwatch.period)
  datasource_uid    = try(each.value.datasource_uid, local.widget_default_values.cloudwatch.datasource_uid)
}

module "elasticache_redis_writes_widget" {
  source = "./modules/widgets/elasticache_redis/writes"

  for_each = { for index, item in try(local.widget_config["elasticache_redis/writes"], []) : index => item }

  coordinates       = each.value.coordinates
  cache_cluster_ids = try(each.value.cache_cluster_ids, [])
  region            = try(each.value.region, local.widget_default_values.cloudwatch.region)
  period            = try(each.value.period, local.widget_default_values.cloudwatch.period)
  datasource_uid    = try(each.value.datasource_uid, local.widget_default_values.cloudwatch.datasource_uid)
}

module "elasticache_redis_reads_widget" {
  source = "./modules/widgets/elasticache_redis/reads"

  for_each = { for index, item in try(local.widget_config["elasticache_redis/reads"], []) : index => item }

  coordinates       = each.value.coordinates
  cache_cluster_ids = try(each.value.cache_cluster_ids, [])
  region            = try(each.value.region, local.widget_default_values.cloudwatch.region)
  period            = try(each.value.period, local.widget_default_values.cloudwatch.period)
  datasource_uid    = try(each.value.datasource_uid, local.widget_default_values.cloudwatch.datasource_uid)
}
