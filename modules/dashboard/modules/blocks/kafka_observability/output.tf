locals {
  common = {
    namespace      = var.namespace
    extra_filters  = var.extra_filters
    cluster_label  = var.cluster_label
    cluster        = var.cluster
    datasource_uid = var.datasource_uid
    period         = var.period
  }
}

output "result" {
  description = "Kafka observability dashboard block widget rows"
  value = [
    [
      { type : "text/title-with-collapse", text : var.block_name }
    ],
    [
      merge(local.common, { type : "kafka/connect_rest_up", width : 8 }),
      merge(local.common, { type : "kafka/connector_state", width : 8 }),
      merge(local.common, { type : "kafka/task_state", width : 8 }),
    ],
    [
      merge(local.common, { type : "kafka/connect_totals", width : 12 }),
      merge(local.common, { type : "kafka/exporter_health", width : 12 }),
    ],
  ]
}
