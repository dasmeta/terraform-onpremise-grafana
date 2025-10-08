# Widget alerts

locals {
  widget_alert_rules = concat(concat([], values(module.block_sla_nginx_alerts).*.alert_rules...), concat([], values(module.block_ingress_nginx_alerts).*.alert_rules...), concat([], values(module.block_service_alerts).*.alert_rules...))

  deep_merge_alert_configs = merge(
    { for index, item in try(local.blocks_by_type["sla"], []) : "${index}_sla" => provider::deepmerge::mergo(var.alerts, try(item.block.alerts, {})) },
    { for index, item in try(local.blocks_by_type["ingress"], []) : "${index}_ingress" => provider::deepmerge::mergo(var.alerts, try(item.block.alerts, {})) },
    { for index, item in try(local.blocks_by_type["service"], []) : "${index}_service" => provider::deepmerge::mergo(var.alerts, try(item.block.alerts, {})) }
  )
}

module "widget_alerts" {
  source = "../alerts/modules/rules"

  folder_name      = var.folder_name
  alert_rules      = local.widget_alert_rules
  annotations      = try(var.alerts.annotations, {})
  labels           = try(var.alerts.labels, {})
  folder_name_uids = var.folder_name_uids

  depends_on = [grafana_folder.this]
}

module "block_sla_nginx_alerts" {
  source = "./modules/alerts/block-sla-nginx"

  for_each = { for index, item in try(local.blocks_by_type["sla"], []) : index => item if(try(merge(var.alerts, try(item.block.alerts, {})).enabled, true) && try(item.block.sla_ingress_type, null) == "nginx") }

  defaults   = try(local.deep_merge_alert_configs["${each.key}_sla"].defaults, {})
  alerts     = try(local.deep_merge_alert_configs["${each.key}_sla"], {})
  datasource = try(each.value.block.datasource_uid, var.data_source.uid)
}

module "block_ingress_nginx_alerts" {
  source = "./modules/alerts/block-ingress-nginx"

  for_each = { for index, item in try(local.blocks_by_type["ingress"], []) : index => item if try(merge(var.alerts, try(item.block.alerts, {})).enabled, true) }

  name       = try(local.deep_merge_alert_configs["${each.key}_ingress"].name, "controller")
  namespace  = try(local.deep_merge_alert_configs["${each.key}_ingress"].namespace, "ingress-nginx")
  defaults   = try(local.deep_merge_alert_configs["${each.key}_ingress"].defaults, {})
  alerts     = try(local.deep_merge_alert_configs["${each.key}_ingress"], {})
  datasource = try(each.value.block.datasource_uid, var.data_source.uid)
}

module "block_service_alerts" {
  source = "./modules/alerts/block-service"

  for_each = { for index, item in flatten([
    for service_index, service in try(local.blocks_by_type["service"], []) : [
      for namespace in distinct(concat(
        try(service.block.namespace, null) == null || startswith(try(service.block.namespace, ""), "$") ? [] : [service.block.namespace],
        try(service.block.alerts.namespaces, [])
      )) : merge(service, { namespace = namespace, service_index = service_index })
    ]]) : index => item if try(merge(var.alerts, try(item.block.alerts, {})).enabled, true)
  }

  name       = each.value.block.name
  namespace  = each.value.namespace
  defaults   = try(local.deep_merge_alert_configs["${each.value.service_index}_service"].defaults, {})
  alerts     = try(local.deep_merge_alert_configs["${each.value.service_index}_service"], {})
  datasource = try(each.value.block.datasource_uid, var.data_source.uid)
}
