output "result" {
  description = "description"
  value = [
    [
      { type : "text/title-with-collapse", text : var.redis_name }
    ],
    [
      { type : "redis/max-uptime", redis_name = var.redis_name, namespace = var.namespace, width : 4 },   //width : 2
      { type : "redis/memory", redis_name = var.redis_name, namespace = var.namespace, width : 4 },       //width : 2
      { type : "redis/total-memory", redis_name : var.redis_name, namespace = var.namespace, width : 4 }, //width : 4
      { type : "redis/cpu", redis_name : var.redis_name, namespace = var.namespace, width : 4 },
      { type : "redis/replicas", redis_name = var.redis_name, namespace = var.namespace, width : 4 },
      { type : "redis/restarts", redis_pod : var.redis_pod, redis_namespace : var.redis_namespace, width : 4 },
    ],
    [
      { type : "redis/errors", redis_name : var.redis_name, namespace : var.namespace, width : 4 },
      { type : "redis/clients", redis_name = var.redis_name, namespace = var.namespace, width : 4 },
      { type : "redis/connections", redis_name = var.redis_name, namespace = var.namespace, width : 4 },
      { type : "redis/latency", redis_name = var.redis_name, namespace = var.namespace, width : 4 },
      { type : "redis/network", redis_name = var.redis_name, namespace = var.namespace, width : 4 },
      { type : "container/network-error", pod : var.redis_pod, width : 4 },
    ],
    [
      { type : "redis/total-commands", redis_name = var.redis_name, namespace = var.namespace, width : 4 },
      { type : "redis/keys", redis_name : var.redis_name, namespace = var.namespace, width : 4 },
      { type : "redis/expired-evicted-keys", redis_name : var.redis_name, namespace = var.namespace, width : 4 },
      { type : "redis/expiring-notexpiring-keys", redis_name : var.redis_name, namespace = var.namespace, width : 4 },
      { type : "redis/hits-misses", redis_name : var.redis_name, namespace = var.namespace, width : 4 },
    ],
    # [
    # { type : "logs/count", aggregated_metric : "redis", width : 4},
    # { type : "logs/error-rate", aggregated_metric : "redis", width : 4},
    # { type : "logs/warning-rate", aggregated_metric : "redis", width : 4},
    # ]
  ]
}
