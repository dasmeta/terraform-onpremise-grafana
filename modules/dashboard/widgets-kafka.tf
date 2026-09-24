# Kafka Connect widgets (block/kafka_observability; types kafka/*)

module "kafka_connect_rest_up_widget" {
  source = "./modules/widgets/kafka/connect_rest_up"

  for_each = { for index, item in try(local.widget_config["kafka/connect_rest_up"], []) : index => item }

  coordinates    = each.value.coordinates
  namespace      = try(each.value.namespace, "$namespace")
  extra_filters  = try(each.value.extra_filters, "")
  cluster_label  = try(each.value.cluster_label, "")
  cluster        = try(each.value.cluster, "")
  period         = try(each.value.period, local.widget_default_values.prometheus.period)
  datasource_uid = try(each.value.datasource_uid, local.widget_default_values.prometheus.datasource_uid)
}

module "kafka_connector_state_widget" {
  source = "./modules/widgets/kafka/connector_state"

  for_each = { for index, item in try(local.widget_config["kafka/connector_state"], []) : index => item }

  coordinates    = each.value.coordinates
  namespace      = try(each.value.namespace, "$namespace")
  extra_filters  = try(each.value.extra_filters, "")
  cluster_label  = try(each.value.cluster_label, "")
  cluster        = try(each.value.cluster, "")
  period         = try(each.value.period, local.widget_default_values.prometheus.period)
  datasource_uid = try(each.value.datasource_uid, local.widget_default_values.prometheus.datasource_uid)
}

module "kafka_task_state_widget" {
  source = "./modules/widgets/kafka/task_state"

  for_each = { for index, item in try(local.widget_config["kafka/task_state"], []) : index => item }

  coordinates    = each.value.coordinates
  namespace      = try(each.value.namespace, "$namespace")
  extra_filters  = try(each.value.extra_filters, "")
  cluster_label  = try(each.value.cluster_label, "")
  cluster        = try(each.value.cluster, "")
  period         = try(each.value.period, local.widget_default_values.prometheus.period)
  datasource_uid = try(each.value.datasource_uid, local.widget_default_values.prometheus.datasource_uid)
}

module "kafka_connect_totals_widget" {
  source = "./modules/widgets/kafka/connect_totals"

  for_each = { for index, item in try(local.widget_config["kafka/connect_totals"], []) : index => item }

  coordinates    = each.value.coordinates
  namespace      = try(each.value.namespace, "$namespace")
  extra_filters  = try(each.value.extra_filters, "")
  cluster_label  = try(each.value.cluster_label, "")
  cluster        = try(each.value.cluster, "")
  period         = try(each.value.period, local.widget_default_values.prometheus.period)
  datasource_uid = try(each.value.datasource_uid, local.widget_default_values.prometheus.datasource_uid)
}

module "kafka_exporter_health_widget" {
  source = "./modules/widgets/kafka/exporter_health"

  for_each = { for index, item in try(local.widget_config["kafka/exporter_health"], []) : index => item }

  coordinates    = each.value.coordinates
  namespace      = try(each.value.namespace, "$namespace")
  extra_filters  = try(each.value.extra_filters, "")
  cluster_label  = try(each.value.cluster_label, "")
  cluster        = try(each.value.cluster, "")
  period         = try(each.value.period, local.widget_default_values.prometheus.period)
  datasource_uid = try(each.value.datasource_uid, local.widget_default_values.prometheus.datasource_uid)
}
