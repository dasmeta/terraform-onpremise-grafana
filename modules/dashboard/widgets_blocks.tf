# Widget blocks
module "block_ingress" {
  source = "./modules/blocks/ingress"

  for_each = { for index, item in try(local.blocks_by_type["ingress"], []) : index => item }

  balancer_name = try(each.value.block.balancer_name, null)
  region        = try(each.value.block.region, null)

  datasource_uid = try(each.value.block.datasource_uid, null)
}

module "block_service" {
  source = "./modules/blocks/service"

  for_each = { for index, item in try(local.blocks_by_type["service"], []) : index => item }

  name                      = each.value.block.name
  namespace                 = try(each.value.block.namespace, "$namespace")
  host                      = try(each.value.block.host, null)
  prometheus_datasource_uid = try(each.value.block.prometheus_datasource_uid, null)
  loki_datasource_uid       = try(each.value.block.loki_datasource_uid, null)
  show_err_logs             = try(each.value.block.show_err_logs, true)
  expr                      = try(each.value.block.expr, "")

}

module "block_sla" {
  source = "./modules/blocks/sla"

  for_each = { for index, item in try(local.blocks_by_type["sla"], []) : index => item }

  balancer_name     = try(each.value.block.balancer_name, null)
  sla_ingress_type  = try(each.value.block.sla_ingress_type, null)
  load_balancer_arn = try(each.value.block.load_balancer_arn, null)
  datasource_uid    = try(each.value.block.datasource_uid, null)
  region            = try(each.value.block.region, null)
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

  region         = try(each.value.block.region, "")
  datasource_uid = try(each.value.block.datasource_uid, "cloudwatch")

}

module "block_alb_ingress" {
  source = "./modules/blocks/alb_ingress"

  for_each = { for index, item in try(local.blocks_by_type["alb_ingress"], []) : index => item }

  load_balancer_arn = try(each.value.block.load_balancer_arn, "")
  region            = try(each.value.block.region, "")
  datasource_uid    = try(each.value.block.datasource_uid, "cloudwatch")
}
