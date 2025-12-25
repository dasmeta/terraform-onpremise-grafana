# RDS widgets

module "rds_cpu_widget" {
  source = "./modules/widgets/rds/cpu"

  for_each = { for index, item in try(local.widget_config["rds/cpu"], []) : index => item }

  coordinates    = each.value.coordinates
  db_identifiers = try(each.value.db_identifiers, [])
  region         = try(each.value.region, local.widget_default_values.cloudwatch.region)
  period         = try(each.value.period, local.widget_default_values.cloudwatch.period)
  datasource_uid = try(each.value.datasource_uid, local.widget_default_values.cloudwatch.datasource_uid)
}

module "rds_memory_widget" {
  source = "./modules/widgets/rds/memory"

  for_each = { for index, item in try(local.widget_config["rds/memory"], []) : index => item }

  coordinates    = each.value.coordinates
  db_identifiers = try(each.value.db_identifiers, [])
  region         = try(each.value.region, local.widget_default_values.cloudwatch.region)
  period         = try(each.value.period, local.widget_default_values.cloudwatch.period)
  datasource_uid = try(each.value.datasource_uid, local.widget_default_values.cloudwatch.datasource_uid)
}

module "rds_network_widget" {
  source = "./modules/widgets/rds/network"

  for_each = { for index, item in try(local.widget_config["rds/network"], []) : index => item }

  coordinates    = each.value.coordinates
  db_identifiers = try(each.value.db_identifiers, [])
  region         = try(each.value.region, local.widget_default_values.cloudwatch.region)
  period         = try(each.value.period, local.widget_default_values.cloudwatch.period)
  datasource_uid = try(each.value.datasource_uid, local.widget_default_values.cloudwatch.datasource_uid)
}

module "rds_connections_widget" {
  source = "./modules/widgets/rds/connections"

  for_each = { for index, item in try(local.widget_config["rds/connections"], []) : index => item }

  coordinates    = each.value.coordinates
  db_identifiers = try(each.value.db_identifiers, [])
  region         = try(each.value.region, local.widget_default_values.cloudwatch.region)
  period         = try(each.value.period, local.widget_default_values.cloudwatch.period)
  datasource_uid = try(each.value.datasource_uid, local.widget_default_values.cloudwatch.datasource_uid)
}

module "rds_read_latency_widget" {
  source = "./modules/widgets/rds/read_latency"

  for_each = { for index, item in try(local.widget_config["rds/read_latency"], []) : index => item }

  coordinates    = each.value.coordinates
  db_identifiers = try(each.value.db_identifiers, [])
  region         = try(each.value.region, local.widget_default_values.cloudwatch.region)
  period         = try(each.value.period, local.widget_default_values.cloudwatch.period)
  datasource_uid = try(each.value.datasource_uid, local.widget_default_values.cloudwatch.datasource_uid)
}

module "rds_write_latency_widget" {
  source = "./modules/widgets/rds/write_latency"

  for_each = { for index, item in try(local.widget_config["rds/write_latency"], []) : index => item }

  coordinates    = each.value.coordinates
  db_identifiers = try(each.value.db_identifiers, [])
  region         = try(each.value.region, local.widget_default_values.cloudwatch.region)
  period         = try(each.value.period, local.widget_default_values.cloudwatch.period)
  datasource_uid = try(each.value.datasource_uid, local.widget_default_values.cloudwatch.datasource_uid)
}

module "rds_read_iops_widget" {
  source = "./modules/widgets/rds/read_iops"

  for_each = { for index, item in try(local.widget_config["rds/read_iops"], []) : index => item }

  coordinates    = each.value.coordinates
  db_identifiers = try(each.value.db_identifiers, [])
  region         = try(each.value.region, local.widget_default_values.cloudwatch.region)
  period         = try(each.value.period, local.widget_default_values.cloudwatch.period)
  datasource_uid = try(each.value.datasource_uid, local.widget_default_values.cloudwatch.datasource_uid)
}
