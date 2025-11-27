# Widget blocks
module "block_ingress" {
  source = "./modules/blocks/ingress"

  for_each  = { for index, item in try(local.blocks_by_type["ingress"], []) : index => item }
  pod       = try(each.value.block.pod, "ingress-nginx-controller")
  namespace = try(each.value.block.namespace, "ingress-nginx")

  datasource_uid = try(each.value.block.datasource_uid, var.data_source.uid, null)
  filter         = try(each.value.block.filter, "")
}

module "block_service" {
  source = "./modules/blocks/service"

  for_each = { for index, item in try(local.blocks_by_type["service"], []) : index => item }

  name                      = each.value.block.name
  namespace                 = try(each.value.block.namespace, "$namespace")
  columns                   = try(each.value.block.columns, 4)
  host                      = try(each.value.block.host, null)
  prometheus_datasource_uid = try(each.value.block.prometheus_datasource_uid, var.data_source.uid)
  loki_datasource_uid       = try(each.value.block.loki_datasource_uid, var.loki_datasource_uid)
  disk_widgets              = try(each.value.block.disk_widgets, {})
  log_widgets               = try(each.value.block.log_widgets, {})
}

module "block_sla" {
  source = "./modules/blocks/sla"

  for_each = { for index, item in try(local.blocks_by_type["sla"], []) : index => item }

  balancer_name     = try(each.value.block.balancer_name, null)
  sla_ingress_type  = try(each.value.block.sla_ingress_type, null)
  load_balancer_arn = try(each.value.block.load_balancer_arn, null)
  datasource_uid    = try(each.value.block.datasource_uid, var.data_source.uid, null)
  region            = try(each.value.block.region, null)
  filter            = try(each.value.block.filter, "")
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
  datasource_uid    = try(each.value.block.datasource_uid, var.data_source.uid, "cloudwatch")
}
