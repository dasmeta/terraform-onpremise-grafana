# Custom widgets
module "custom_widget" {
  source = "./modules/widgets/custom"

  for_each = { for index, item in try(local.widget_config["custom"], []) : index => item }

  title       = each.value.title
  metrics     = each.value.metrics
  data_source = each.value.data_source
  coordinates = each.value.coordinates
  period      = each.value.period

  expressions        = each.value.expressions
  cloudwatch_targets = each.value.cloudwatch_targets



  # container
  # container = each.value.container
  # cluster   = try(each.value.cluster, null)
  # namespace = each.value.namespace
  # by_pod    = try(each.value.by_pod, false)

}
