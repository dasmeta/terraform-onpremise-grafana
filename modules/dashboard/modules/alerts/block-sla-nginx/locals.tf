locals {
  latency_interval      = coalesce(var.alerts.latency.interval, var.defaults.interval)
  availability_interval = coalesce(var.alerts.availability.interval, var.defaults.interval)

  latency_metric_filter = trimspace(
    trimspace(var.alerts.latency.metric_filter) != "" ? var.alerts.latency.metric_filter : var.defaults.metric_filter
  )
  availability_metric_filter = trimspace(
    trimspace(var.alerts.availability.metric_filter) != "" ? var.alerts.availability.metric_filter : var.defaults.metric_filter
  )

  latency_metric_filter_suffix      = local.latency_metric_filter == "" ? "" : ", ${local.latency_metric_filter}"
  availability_metric_filter_suffix = local.availability_metric_filter == "" ? "" : ", ${local.availability_metric_filter}"
}
