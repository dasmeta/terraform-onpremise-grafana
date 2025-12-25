output "result" {
  description = "description"
  value = [
    [
      { type : "text/title-with-collapse", text : var.block_name }
    ],
    [
      { type : "rds/cpu", db_identifiers = var.db_identifiers, width = 8, region = var.region, datasource_uid = var.datasource_uid, period = var.period },
      { type : "rds/memory", db_identifiers = var.db_identifiers, width = 8, region = var.region, datasource_uid = var.datasource_uid, period = var.period },
      { type : "rds/network", db_identifiers = var.db_identifiers, width = 8, region = var.region, datasource_uid = var.datasource_uid, period = var.period },
    ],
    [
      { type : "rds/connections", db_identifiers = var.db_identifiers, region = var.region, datasource_uid = var.datasource_uid, period = var.period },
      { type : "rds/read_latency", db_identifiers = var.db_identifiers, region = var.region, datasource_uid = var.datasource_uid, period = var.period },
      { type : "rds/write_latency", db_identifiers = var.db_identifiers, region = var.region, datasource_uid = var.datasource_uid, period = var.period },
      { type : "rds/read_iops", db_identifiers = var.db_identifiers, region = var.region, datasource_uid = var.datasource_uid, period = var.period }
    ],
  ]
}
