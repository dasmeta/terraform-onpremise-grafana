# Container widgets
module "instance_cpu_widget" {
  source = "./modules/widgets/cloudwatch/instance_cpu"

  for_each = { for index, item in try(local.widget_config["cloudwatch/instance_cpu"], []) : index => item }

  # data_source = try(each.value.data_source, { type = "Cloudwatch", uid = "cloudwatch" })
  datasource_type = try(each.value.datasource_type, null)
  datasource_uid  = try(each.value.datasource_uid, null)
  coordinates     = each.value.coordinates
  # period      = each.value.period
  namespace = each.value.namespace
  region    = each.value.region
}

module "instance_disk_widget" {
  source = "./modules/widgets/cloudwatch/instance_disk"

  for_each = { for index, item in try(local.widget_config["cloudwatch/instance_disk"], []) : index => item }

  # data_source = try(each.value.data_source, { type = "Cloudwatch", uid = "cloudwatch" })
  datasource_type = try(each.value.datasource_type, null)
  datasource_uid  = try(each.value.datasource_uid, null)
  coordinates     = each.value.coordinates
  # period      = each.value.period
  namespace = each.value.namespace

  region = each.value.region
}

module "instance_network_widget" {
  source = "./modules/widgets/cloudwatch/instance_network"

  for_each = { for index, item in try(local.widget_config["cloudwatch/instance_network"], []) : index => item }

  # data_source = try(each.value.data_source, { type = "Cloudwatch", uid = "cloudwatch" })
  datasource_type = try(each.value.datasource_type, null)
  datasource_uid  = try(each.value.datasource_uid, null)
  coordinates     = each.value.coordinates
  # period      = each.value.period
  namespace = each.value.namespace

  region = each.value.region
}
