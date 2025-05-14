# SLA/SLO/SLI widgets

module "widget_sla_slo_sli_main" {
  source = "./modules/widgets/sla-slo-sli/main"

  for_each = { for index, item in try(local.widget_config["sla-slo-sli/main"], []) : index => item }

  data_source = each.value.data_source
  coordinates = each.value.coordinates
  period      = each.value.period

  balancer_name = try(each.value.balancer_name, null)

}

module "widget_sla_slo_sli_latency" {
  source = "./modules/widgets/sla-slo-sli/latency"

  for_each = { for index, item in try(local.widget_config["sla-slo-sli/latency"], []) : index => item }

  data_source = each.value.data_source
  coordinates = each.value.coordinates
  period      = each.value.period
  histogram   = try(each.value.histogram, false)

  balancer_name = try(each.value.balancer_name, null)

}
