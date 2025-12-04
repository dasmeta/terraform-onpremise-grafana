# Pod widgets
module "pod_cpu_widget" {
  source = "./modules/widgets/pod/cpu"

  for_each = { for index, item in try(local.widget_config["pod/cpu"], []) : index => item }

  data_source = try(each.value.data_source, {})
  coordinates = each.value.coordinates
  period      = try(each.value.period, local.widget_default_values.prometheus.period)

  # pod
  pod       = each.value.pod
  namespace = each.value.namespace
  by_pod    = try(each.value.by_pod, false)
}

module "pod_memory_widget" {
  source = "./modules/widgets/pod/memory"

  for_each = { for index, item in try(local.widget_config["pod/memory"], []) : index => item }

  data_source = try(each.value.data_source, {})
  coordinates = each.value.coordinates
  period      = try(each.value.period, local.widget_default_values.prometheus.period)

  # pod
  pod       = each.value.pod
  namespace = each.value.namespace
}

module "pod_restarts_widget" {
  source = "./modules/widgets/pod/restarts"

  for_each = { for index, item in try(local.widget_config["pod/restarts"], []) : index => item }

  datasource_uid = try(each.value.datasource_uid, {})
  coordinates    = each.value.coordinates
  period         = try(each.value.period, local.widget_default_values.prometheus.period)

  # pod
  pod       = each.value.pod
  namespace = each.value.namespace
}

module "deployment_replicas_widget" {
  source = "./modules/widgets/deployment/replicas"

  for_each = { for index, item in try(local.widget_config["deployment/replicas"], []) : index => item }

  datasource_uid = try(each.value.datasource_uid, {})
  coordinates    = each.value.coordinates
  period         = try(each.value.period, local.widget_default_values.prometheus.period)

  # deployment
  deployment = each.value.deployment
  namespace  = each.value.namespace
}
