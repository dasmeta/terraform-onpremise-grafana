module "this" {
  source = "../.."
  name   = "Dashboard Example"

  rows = [
    # Elasticache Redis Block
    { "type" : "block/elasticache_redis", "block_name" : "Elasticache Redis", "cache_cluster_ids" : ["redis-name-001", "redis-name-002"] },
    # RDS Block
    { "type" : "block/rds", "block_name" : "RDS", "db_identifiers" : ["rds-name"] },
    # SES Block
    { type : "block/ses", block_name : "AWS SES", region : "eu-central-1", sending_quota_standard_options : { max : 100000 } },
  ]
}
