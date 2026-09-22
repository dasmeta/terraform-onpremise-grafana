output "alert_rules" {
  value = concat(
    coalesce(var.alerts.latency.enabled, var.defaults.enabled, false) ? [
      {
        name           = "sla latency for ${coalesce(var.alerts.latency.interval, var.defaults.interval)} interval got increased and is > ${var.alerts.latency.threshold} seconds"
        summary        = "{{ .Labels.alertname }} it is already ${coalesce(var.alerts.latency.pending_period, var.defaults.pending_period)}"
        group          = try(coalesce(var.alerts.latency.group, var.defaults.group), null)
        no_data_state  = coalesce(var.alerts.latency.no_data_state, var.defaults.no_data_state, "NoData")
        exec_err_state = coalesce(var.alerts.latency.exec_err_state, var.defaults.exec_err_state, "Error")
        datasource     = var.datasource
        expr           = "(sum(rate(nginx_ingress_controller_request_duration_seconds_sum{status=~\"2..|3..\"${local.latency_metric_filter_suffix}}[${local.latency_interval}])) / sum(rate(nginx_ingress_controller_request_duration_seconds_count{status=~\"2..|3..\"${local.latency_metric_filter_suffix}}[${local.latency_interval}]))) unless sum(rate(nginx_ingress_controller_request_duration_seconds_count{status=~\"2..|3..\"${local.latency_metric_filter_suffix}}[${local.latency_interval}])) == 0"
        pending_period = coalesce(var.alerts.latency.pending_period, var.defaults.pending_period)
        function       = "last"
        equation       = "gt"
        threshold      = var.alerts.latency.threshold
        filters        = {}
        labels         = merge(var.defaults.labels, var.alerts.latency.labels)
        annotations = merge({
          "threshold" = var.alerts.latency.threshold,
          "metric"    = "request_latency_seconds",
          "impact"    = "Service response latency is above the SLO"
          "component" = "ingress"
          "resource"  = "-"
        }, try(var.alerts.latency.annotations, {}))
        settings_mode        = "replaceNN"
        settings_replaceWith = 0
      }
    ] : [],
    coalesce(var.alerts.availability.enabled, var.defaults.enabled, false) ? [
      {
        name           = "sla availability for ${coalesce(var.alerts.availability.interval, var.defaults.interval)} interval got decreased and is < ${coalesce(var.alerts.availability.threshold, var.defaults.threshold_percent)} percent"
        summary        = "{{ .Labels.alertname }} it is already ${coalesce(var.alerts.availability.pending_period, var.defaults.pending_period)}"
        group          = try(coalesce(var.alerts.availability.group, var.defaults.group), null)
        no_data_state  = coalesce(var.alerts.availability.no_data_state, var.defaults.no_data_state, "NoData")
        exec_err_state = coalesce(var.alerts.availability.exec_err_state, var.defaults.exec_err_state, "Error")
        datasource     = var.datasource
        expr           = "(100 * sum(rate(nginx_ingress_controller_requests{status!~\"5..\"${local.availability_metric_filter_suffix}}[${local.availability_interval}])) / sum(rate(nginx_ingress_controller_requests{${local.availability_metric_filter}}[${local.availability_interval}]))) unless sum(rate(nginx_ingress_controller_requests{${local.availability_metric_filter}}[${local.availability_interval}])) == 0"
        pending_period = coalesce(var.alerts.availability.pending_period, var.defaults.pending_period)
        function       = "last"
        equation       = "lt"
        threshold      = coalesce(var.alerts.availability.threshold, var.defaults.threshold_percent)
        filters        = {}
        labels         = merge(var.defaults.labels, var.alerts.availability.labels)
        annotations = merge({
          "threshold" = coalesce(var.alerts.availability.threshold, var.defaults.threshold_percent),
          "metric"    = "requests",
          "impact"    = "Service might be unavailable"
          "component" = "ingress"
          "resource"  = "-"
        }, try(var.alerts.availability.annotations, {}))
        settings_mode        = "replaceNN"
        settings_replaceWith = 0
      }
    ] : [],
    []
  )
  description = "The generated alert rules"
}
