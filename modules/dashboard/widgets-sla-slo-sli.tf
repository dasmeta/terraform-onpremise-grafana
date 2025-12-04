# SLA/SLO/SLI widgets

module "widget_sla_slo_sli_nginx_availability" {
  source = "./modules/widgets/sla-slo-sli/nginx_availability"

  for_each = { for index, item in try(local.widget_config["sla-slo-sli/nginx_availability"], []) : index => item }

  datasource_uid = try(each.value.datasource_uid, null)
  coordinates    = each.value.coordinates
  period         = try(each.value.period, local.widget_default_values.prometheus.period)
  histogram      = try(each.value.histogram, false)
  filter         = try(each.value.filter, "")
}

module "widget_sla_slo_sli_nginx_latency" {
  source = "./modules/widgets/sla-slo-sli/nginx_latency"

  for_each = { for index, item in try(local.widget_config["sla-slo-sli/nginx_latency"], []) : index => item }

  datasource_uid = try(each.value.datasource_uid, null)
  coordinates    = each.value.coordinates
  period         = try(each.value.period, local.widget_default_values.prometheus.period)
  histogram      = try(each.value.histogram, false)
  filter         = try(each.value.filter, "")
}

module "widget_sla_slo_sli_alb_availability" {
  source = "./modules/widgets/sla-slo-sli/alb_availability"

  for_each = { for index, item in try(local.widget_config["sla-slo-sli/alb_availability"], []) : index => item }

  coordinates       = each.value.coordinates
  load_balancer_arn = try(each.value.load_balancer_arn, local.widget_default_values.cloudwatch.load_balancer_arn)
  region            = try(each.value.region, local.widget_default_values.cloudwatch.region)
  period            = try(each.value.period, local.widget_default_values.cloudwatch.period)
  datasource_uid    = try(each.value.datasource_uid, local.widget_default_values.cloudwatch.datasource_uid)
}

module "widget_sla_slo_sli_alb_latency" {
  source = "./modules/widgets/sla-slo-sli/alb_latency"

  for_each = { for index, item in try(local.widget_config["sla-slo-sli/alb_latency"], []) : index => item }

  coordinates       = each.value.coordinates
  load_balancer_arn = try(each.value.load_balancer_arn, local.widget_default_values.cloudwatch.load_balancer_arn)
  region            = try(each.value.region, local.widget_default_values.cloudwatch.region)
  period            = try(each.value.period, local.widget_default_values.cloudwatch.period)
  datasource_uid    = try(each.value.datasource_uid, local.widget_default_values.cloudwatch.datasource_uid)
}
