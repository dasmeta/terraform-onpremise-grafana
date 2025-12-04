# Container widgets
module "instance_cpu_widget" {
  source = "./modules/widgets/cloudwatch/instance_cpu"

  for_each = { for index, item in try(local.widget_config["cloudwatch/instance_cpu"], []) : index => item }

  coordinates    = each.value.coordinates
  namespace      = each.value.namespace
  region         = try(each.value.region, local.widget_default_values.cloudwatch.region)
  period         = try(each.value.period, local.widget_default_values.cloudwatch.period)
  datasource_uid = try(each.value.datasource_uid, local.widget_default_values.cloudwatch.datasource_uid)
}

module "instance_disk_widget" {
  source = "./modules/widgets/cloudwatch/instance_disk"

  for_each = { for index, item in try(local.widget_config["cloudwatch/instance_disk"], []) : index => item }

  coordinates    = each.value.coordinates
  namespace      = each.value.namespace
  region         = try(each.value.region, local.widget_default_values.cloudwatch.region)
  period         = try(each.value.period, local.widget_default_values.cloudwatch.period)
  datasource_uid = try(each.value.datasource_uid, local.widget_default_values.cloudwatch.datasource_uid)
}

module "instance_network_widget" {
  source = "./modules/widgets/cloudwatch/instance_network"

  for_each = { for index, item in try(local.widget_config["cloudwatch/instance_network"], []) : index => item }

  coordinates    = each.value.coordinates
  namespace      = each.value.namespace
  region         = try(each.value.region, local.widget_default_values.cloudwatch.region)
  period         = try(each.value.period, local.widget_default_values.cloudwatch.period)
  datasource_uid = try(each.value.datasource_uid, local.widget_default_values.cloudwatch.datasource_uid)
}
