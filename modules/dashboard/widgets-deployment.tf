# Pod widgets
module "deployment_replicas_widget" {
  source = "./modules/widgets/deployment/replicas"

  for_each = { for index, item in try(local.widget_config["deployment/replicas"], []) : index => item }

  data_source = try(each.value.data_source, {})
  coordinates = each.value.coordinates
  period      = each.value.period

  # deployment
  deployment = each.value.deployment
  namespace  = each.value.namespace
}
