# Pod widgets
module "pod_cpu_widget" {
  source = "./modules/widgets/pod/cpu"

  for_each = { for index, item in try(local.widget_config["pod/cpu"], []) : index => item }

  data_source = try(each.value.data_source, {})
  coordinates = each.value.coordinates
  period      = each.value.period

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
  period      = each.value.period

  # pod
  pod       = each.value.pod
  namespace = each.value.namespace
}

module "pod_restarts_widget" {
  source = "./modules/widgets/pod/restarts"

  for_each = { for index, item in try(local.widget_config["pod/restarts"], []) : index => item }

  data_source = try(each.value.data_source, {})
  coordinates = each.value.coordinates
  period      = each.value.period

  # pod
  pod       = each.value.pod
  namespace = each.value.namespace
}
