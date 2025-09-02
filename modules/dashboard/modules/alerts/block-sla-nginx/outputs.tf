output "alert_rules" {
  value = concat(
    coalesce(var.alerts.latency.enabled, var.defaults.enabled, false) ? [
      {
        name           = "sla latency for ${coalesce(var.alerts.latency.interval, var.defaults.interval)} interval got increased and is > ${var.alerts.latency.threshold} seconds"
        summary        = "{{ .Labels.alertname }} it is already ${coalesce(var.alerts.latency.pending_period, var.defaults.pending_period)}"
        group          = try(coalesce(var.alerts.latency.group, var.defaults.group), null)
        no_data_state  = coalesce(var.alerts.latency.no_data_state, var.defaults.no_data_state, "NoData")
        datasource     = var.datasource
        expr           = "avg(rate(nginx_ingress_controller_request_duration_seconds_sum{status=~'[^1]..', ${coalesce(var.alerts.latency.metric_filter, var.defaults.metric_filter)}}[${coalesce(var.alerts.latency.interval, var.defaults.interval)}]))/avg(rate(nginx_ingress_controller_request_duration_seconds_count{status=~'[^1]..', ${coalesce(var.alerts.latency.metric_filter, var.defaults.metric_filter)}}[${coalesce(var.alerts.latency.interval, var.defaults.interval)}])) unless (avg(rate(nginx_ingress_controller_request_duration_seconds_count{status=~'[^1]..', ${coalesce(var.alerts.latency.metric_filter, var.defaults.metric_filter)}}[${coalesce(var.alerts.latency.interval, var.defaults.interval)}]))) == 0"
        pending_period = coalesce(var.alerts.latency.pending_period, var.defaults.pending_period)
        function       = "last"
        equation       = "gt"
        threshold      = var.alerts.latency.threshold
        filters        = {}
        labels         = merge(var.defaults.labels, var.alerts.latency.labels)
        annotations = merge({
          "threshold" = coalesce(var.alerts.availability.threshold, var.defaults.threshold_percent),
          "metric"    = "requests",
          "impact"    = "Service might response slower"
          "component" = "ingress"
          "resource"  = "-"
        }, var.alerts.availability.annotations)
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
        datasource     = var.datasource
        expr           = "(1 - (sum(rate(nginx_ingress_controller_requests{status=~'5..|499', ${coalesce(var.alerts.availability.metric_filter, var.defaults.metric_filter)}}[${coalesce(var.alerts.availability.interval, var.defaults.interval)}])) / sum(rate(nginx_ingress_controller_requests{${coalesce(var.alerts.availability.metric_filter, var.defaults.metric_filter)}}[${coalesce(var.alerts.availability.interval, var.defaults.interval)}])))) * 100 unless (sum(rate(nginx_ingress_controller_requests{${coalesce(var.alerts.availability.metric_filter, var.defaults.metric_filter)}}[${coalesce(var.alerts.availability.interval, var.defaults.interval)}]))) == 0"
        pending_period = coalesce(var.alerts.availability.pending_period, var.defaults.pending_period)
        function       = "last"
        equation       = "lt"
        threshold      = coalesce(var.alerts.availability.threshold, var.defaults.threshold_percent)
        filters        = {}
        labels         = merge(var.defaults.labels, var.alerts.availability.labels)
        annotations = merge({
          "threshold" = coalesce(var.alerts.availability.threshold, var.defaults.threshold_percent),
          "metric"    = "requests",
          "impact"    = "Service might response slower"
          "component" = "ingress"
          "resource"  = "-"
        }, var.alerts.availability.annotations)
        settings_mode        = "replaceNN"
        settings_replaceWith = 0
      }
    ] : [],
    []
  )
  description = "The generated alert rules"
}
