# Widget blocks
module "block_ingress" {
  source = "./modules/blocks/ingress"

  for_each = { for index, item in try(local.blocks_by_type["ingress"], []) : index => item }

  balancer_name = try(each.value.block.balancer_name, null)
  account_id    = try(each.value.block.account_id, null)
  region        = try(each.value.block.region, null)
}

module "block_service" {
  source = "./modules/blocks/service"

  for_each = { for index, item in try(local.blocks_by_type["service"], []) : index => item }

  name             = each.value.block.name
  balancer_name    = try(each.value.block.balancer_name, null)
  target_group_arn = try(each.value.block.target_group_arn, null)
  healthcheck_id   = try(each.value.block.healthcheck_id, null)
  cluster          = try(each.value.block.cluster, null)
  namespace        = try(each.value.block.namespace, "$namespace")
  version_label    = try(each.value.block.version_label, "app-version")
  log_group_name   = try(each.value.block.log_group_name, null)
  host             = try(each.value.block.host, null)
}

module "block_sla" {
  source = "./modules/blocks/sla"

  for_each = { for index, item in try(local.blocks_by_type["sla"], []) : index => item }

  balancer_name = try(each.value.block.balancer_name, null)
}

module "block_redis" {
  source = "./modules/blocks/redis"

  for_each = { for index, item in try(local.blocks_by_type["redis"], []) : index => item }

  redis_name      = each.value.block.redis_name
  redis_pod       = try(each.value.block.redis_pod, "")
  redis_namespace = try(each.value.block.redis_namespace, "")
  namespace       = try(each.value.block.namespace, "$namespace")
}

module "block_cloudwatch" {
  source = "./modules/blocks/cloudwatch"

  for_each = { for index, item in try(local.blocks_by_type["cloudwatch"], []) : index => item }

  region = try(each.value.block.region, "")
}
