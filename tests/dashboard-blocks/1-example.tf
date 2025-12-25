module "this" {
  source = "../../dashboard"
  name   = "Dashboard Example"
  rows = [
    # SLA Block
    { "type" : "block/sla", "sla_ingress_type" : "nginx" },
    # Ingress Block
    { "type" : "block/ingress", "datasource_uid" : "prometheus" },
    # Service Block
    { "name" : "dev-deployment1", "namespace" : "dev", "type" : "block/service" },
    # Elasticache Redis Block
    { "type" : "block/elasticache_redis", "block_name" : "Elasticache Redis", "cache_cluster_ids" : ["redis-name-001", "redis-name-002"] },
    # RDS Block
    { "type" : "block/rds", "block_name" : "RDS", "db_identifiers" : ["rds-name"] }
  ]
}
