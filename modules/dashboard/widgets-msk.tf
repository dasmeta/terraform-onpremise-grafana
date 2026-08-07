# MSK widgets

module "msk_cpu_widget" {
  source = "./modules/widgets/msk/cpu"

  for_each = { for index, item in try(local.widget_config["msk/cpu"], []) : index => item }

  coordinates    = each.value.coordinates
  cluster_names  = try(each.value.cluster_names, [])
  broker_ids     = try(each.value.broker_ids, ["1", "2", "3"])
  region         = try(each.value.region, local.widget_default_values.cloudwatch.region)
  period         = try(each.value.period, local.widget_default_values.cloudwatch.period)
  datasource_uid = try(each.value.datasource_uid, local.widget_default_values.cloudwatch.datasource_uid)
}

module "msk_memory_widget" {
  source = "./modules/widgets/msk/memory"

  for_each = { for index, item in try(local.widget_config["msk/memory"], []) : index => item }

  coordinates    = each.value.coordinates
  cluster_names  = try(each.value.cluster_names, [])
  broker_ids     = try(each.value.broker_ids, ["1", "2", "3"])
  region         = try(each.value.region, local.widget_default_values.cloudwatch.region)
  period         = try(each.value.period, local.widget_default_values.cloudwatch.period)
  datasource_uid = try(each.value.datasource_uid, local.widget_default_values.cloudwatch.datasource_uid)
}

module "msk_throughput_in_widget" {
  source = "./modules/widgets/msk/throughput_in"

  for_each = { for index, item in try(local.widget_config["msk/throughput_in"], []) : index => item }

  coordinates    = each.value.coordinates
  cluster_names  = try(each.value.cluster_names, [])
  region         = try(each.value.region, local.widget_default_values.cloudwatch.region)
  period         = try(each.value.period, local.widget_default_values.cloudwatch.period)
  datasource_uid = try(each.value.datasource_uid, local.widget_default_values.cloudwatch.datasource_uid)
}

module "msk_throughput_out_widget" {
  source = "./modules/widgets/msk/throughput_out"

  for_each = { for index, item in try(local.widget_config["msk/throughput_out"], []) : index => item }

  coordinates    = each.value.coordinates
  cluster_names  = try(each.value.cluster_names, [])
  region         = try(each.value.region, local.widget_default_values.cloudwatch.region)
  period         = try(each.value.period, local.widget_default_values.cloudwatch.period)
  datasource_uid = try(each.value.datasource_uid, local.widget_default_values.cloudwatch.datasource_uid)
}

module "msk_partitions_widget" {
  source = "./modules/widgets/msk/partitions"

  for_each = { for index, item in try(local.widget_config["msk/partitions"], []) : index => item }

  coordinates    = each.value.coordinates
  cluster_names  = try(each.value.cluster_names, [])
  region         = try(each.value.region, local.widget_default_values.cloudwatch.region)
  period         = try(each.value.period, local.widget_default_values.cloudwatch.period)
  datasource_uid = try(each.value.datasource_uid, local.widget_default_values.cloudwatch.datasource_uid)
}

module "msk_offline_partitions_widget" {
  source = "./modules/widgets/msk/offline_partitions"

  for_each = { for index, item in try(local.widget_config["msk/offline_partitions"], []) : index => item }

  coordinates    = each.value.coordinates
  cluster_names  = try(each.value.cluster_names, [])
  region         = try(each.value.region, local.widget_default_values.cloudwatch.region)
  period         = try(each.value.period, local.widget_default_values.cloudwatch.period)
  datasource_uid = try(each.value.datasource_uid, local.widget_default_values.cloudwatch.datasource_uid)
}

module "msk_consumer_lag_widget" {
  source = "./modules/widgets/msk/consumer_lag"

  for_each = { for index, item in try(local.widget_config["msk/consumer_lag"], []) : index => item }

  coordinates     = each.value.coordinates
  cluster_names   = try(each.value.cluster_names, [])
  consumer_groups = try(each.value.consumer_groups, [])
  region          = try(each.value.region, local.widget_default_values.cloudwatch.region)
  period          = try(each.value.period, local.widget_default_values.cloudwatch.period)
  datasource_uid  = try(each.value.datasource_uid, local.widget_default_values.cloudwatch.datasource_uid)
}
