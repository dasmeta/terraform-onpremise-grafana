output "result" {
  description = "MSK dashboard block widget rows"
  value = [
    [
      { type : "text/title-with-collapse", text : var.block_name }
    ],
    [
      { type : "msk/cpu", cluster_names = var.cluster_names, broker_ids = var.broker_ids, width = 8, region = var.region, datasource_uid = var.datasource_uid, period = var.period },
      { type : "msk/memory", cluster_names = var.cluster_names, broker_ids = var.broker_ids, width = 8, region = var.region, datasource_uid = var.datasource_uid, period = var.period },
      { type : "msk/throughput_in", cluster_names = var.cluster_names, width = 8, region = var.region, datasource_uid = var.datasource_uid, period = var.period },
    ],
    [
      { type : "msk/throughput_out", cluster_names = var.cluster_names, width = 8, region = var.region, datasource_uid = var.datasource_uid, period = var.period },
      { type : "msk/partitions", cluster_names = var.cluster_names, width = 8, region = var.region, datasource_uid = var.datasource_uid, period = var.period },
      { type : "msk/offline_partitions", cluster_names = var.cluster_names, width = 8, region = var.region, datasource_uid = var.datasource_uid, period = var.period },
    ],
    [
      { type : "msk/consumer_lag", cluster_names = var.cluster_names, consumer_groups = var.consumer_groups, width = 24, region = var.region, datasource_uid = var.datasource_uid, period = var.period },
    ],
  ]
}
