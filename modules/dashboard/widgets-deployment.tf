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

module "deployment_errors_widget" {
  source = "./modules/widgets/deployment/errors"

  for_each = { for index, item in try(local.widget_config["deployment/errors"], []) : index => item }

  datasource_uid = try(each.value.datasource_uid, {})
  coordinates    = each.value.coordinates
  period         = each.value.period

  # deployment
  deployment = each.value.deployment
}
