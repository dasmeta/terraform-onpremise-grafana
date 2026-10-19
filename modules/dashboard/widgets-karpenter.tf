# Karpenter widgets (block/karpenter; types karpenter/*), one module renders every karpenter/<panel> type
module "karpenter_widget" {
  source = "./modules/widgets/karpenter"

  for_each = { for index, item in flatten([for type, items in local.widget_config : items if startswith(type, "karpenter/")]) : index => item }

  panel          = trimprefix(each.value.type, "karpenter/")
  coordinates    = each.value.coordinates
  namespace      = try(each.value.namespace, "karpenter")
  extra_filters  = try(each.value.extra_filters, "")
  period         = try(each.value.period, local.widget_default_values.prometheus.period)
  datasource_uid = try(each.value.datasource_uid, local.widget_default_values.prometheus.datasource_uid)
}
