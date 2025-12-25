output "result" {
  description = "description"
  value = [
    [
      { type : "text/title-with-collapse", text : var.block_name }
    ],
    [
      { type : "elasticache_redis/cpu", cache_cluster_ids = var.cache_cluster_ids, width = 8, region = var.region, datasource_uid = var.datasource_uid, period = var.period },
      { type : "elasticache_redis/memory", cache_cluster_ids = var.cache_cluster_ids, width = 8, region = var.region, datasource_uid = var.datasource_uid, period = var.period },
      { type : "elasticache_redis/capacity", cache_cluster_ids = var.cache_cluster_ids, width = 8, region = var.region, datasource_uid = var.datasource_uid, period = var.period },
    ],
    [
      { type : "elasticache_redis/latency", cache_cluster_ids = var.cache_cluster_ids, width = 8, region = var.region, datasource_uid = var.datasource_uid, period = var.period },
      { type : "elasticache_redis/connections", cache_cluster_ids = var.cache_cluster_ids, width = 8, region = var.region, datasource_uid = var.datasource_uid, period = var.period },
      { type : "elasticache_redis/new_connections", cache_cluster_ids = var.cache_cluster_ids, width = 8, region = var.region, datasource_uid = var.datasource_uid, period = var.period },

    ],
    [
      { type : "elasticache_redis/hit_rate", cache_cluster_ids = var.cache_cluster_ids, width = 8, region = var.region, datasource_uid = var.datasource_uid, period = var.period },
      { type : "elasticache_redis/writes", cache_cluster_ids = var.cache_cluster_ids, width = 8, region = var.region, datasource_uid = var.datasource_uid, period = var.period },
      { type : "elasticache_redis/reads", cache_cluster_ids = var.cache_cluster_ids, width = 8, region = var.region, datasource_uid = var.datasource_uid, period = var.period }
    ],
  ]
}
