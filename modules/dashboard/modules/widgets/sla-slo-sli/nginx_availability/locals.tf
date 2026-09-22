locals {
  metric_filter        = trimspace(var.filter)
  metric_filter_suffix = local.metric_filter == "" ? "" : ", ${local.metric_filter}"
}
