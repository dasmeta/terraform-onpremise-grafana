# Single widgets
module "widget_custom" {
  source = "./modules/widgets/custom"

  for_each = { for index, item in try(local.widget_config["custom"], []) : index => item }

  data_source = each.value.data_source
  coordinates = each.value.coordinates
  period      = each.value.period
  decimals    = try(each.value.decimals, 0)
  fillOpacity = try(each.value.fillOpacity, 0)
  yAxis       = each.value.yAxis

  # metric
  title       = each.value.title
  metrics     = each.value.metrics
  expressions = each.value.expressions
}
