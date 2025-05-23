# SLA/SLO/SLI widgets

module "widget_sla_slo_sli_nginx_main" {
  source = "./modules/widgets/sla-slo-sli/nginx_main"

  for_each = { for index, item in try(local.widget_config["sla-slo-sli/nginx_main"], []) : index => item }

  datasource_uid = try(each.value.datasource_uid, null)
  coordinates    = each.value.coordinates
  period         = each.value.period

  balancer_name = try(each.value.balancer_name, null)

}

module "widget_sla_slo_sli_nginx_latency" {
  source = "./modules/widgets/sla-slo-sli/nginx_latency"

  for_each = { for index, item in try(local.widget_config["sla-slo-sli/nginx_latency"], []) : index => item }

  datasource_uid = try(each.value.datasource_uid, null)
  coordinates    = each.value.coordinates
  period         = each.value.period
  histogram      = try(each.value.histogram, false)

  balancer_name = try(each.value.balancer_name, null)

}

module "widget_sla_slo_sli_alb_availability" {
  source = "./modules/widgets/sla-slo-sli/alb_availability"

  for_each = { for index, item in try(local.widget_config["sla-slo-sli/alb_availability"], []) : index => item }

  datasource_uid    = try(each.value.datasource_uid, null)
  load_balancer_arn = each.value.load_balancer_arn
  coordinates       = each.value.coordinates
  region            = each.value.region

}

module "widget_sla_slo_sli_alb_latency" {
  source = "./modules/widgets/sla-slo-sli/alb_latency"

  for_each = { for index, item in try(local.widget_config["sla-slo-sli/alb_latency"], []) : index => item }

  datasource_uid    = try(each.value.datasource_uid, null)
  load_balancer_arn = each.value.load_balancer_arn
  coordinates       = each.value.coordinates
  region            = each.value.region

}
