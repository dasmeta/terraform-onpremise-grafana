output "alert_rules" {
  value = concat(
    coalesce(var.alerts.latency.enabled, var.defaults.enabled, false) ? [
      {
        name                 = "nginx ingress requests latency(by host, path) for ${coalesce(var.alerts.latency.interval, var.defaults.interval)} interval is > ${var.alerts.latency.threshold} seconds"
        summary              = "{{ .Labels.alertname }} on host={{ $labels.host }} path={{ $labels.path }} it is already ${coalesce(var.alerts.latency.pending_period, var.defaults.pending_period)}"
        group                = try(coalesce(var.alerts.latency.group, var.defaults.group), null)
        datasource           = var.datasource
        no_data_state        = coalesce(var.alerts.latency.no_data_state, var.defaults.no_data_state, "NoData")
        expr                 = "avg(rate(nginx_ingress_controller_request_duration_seconds_sum{status=~'[^1]..', ${coalesce(var.alerts.latency.metric_filter, var.defaults.metric_filter)}}[${coalesce(var.alerts.latency.interval, var.defaults.interval)}])) by (host, path)/avg(rate(nginx_ingress_controller_request_duration_seconds_count{${coalesce(var.alerts.latency.metric_filter, var.defaults.metric_filter)}}[${coalesce(var.alerts.latency.interval, var.defaults.interval)}])) by (host, path)"
        pending_period       = coalesce(var.alerts.latency.pending_period, var.defaults.pending_period)
        function             = "last"
        equation             = "gt"
        threshold            = var.alerts.latency.threshold
        filters              = {}
        labels               = merge(var.defaults.labels, var.alerts.latency.labels)
        settings_mode        = "replaceNN"
        settings_replaceWith = 0
      }
    ] : [],
    coalesce(var.alerts.failed.enabled, var.defaults.enabled, false) ? [
      {
        name                 = "nginx ingress failed(5xx|499) requests count(by host, path) for ${coalesce(var.alerts.failed.interval, var.defaults.interval)} interval is > ${100 - coalesce(var.alerts.failed.threshold_percent, var.defaults.threshold_percent)} percent"
        summary              = "{{ .Labels.alertname }} on host={{ $labels.host }} path={{ $labels.path }} it is already ${coalesce(var.alerts.failed.pending_period, var.defaults.pending_period)}"
        group                = try(coalesce(var.alerts.failed.group, var.defaults.group), null)
        datasource           = var.datasource
        no_data_state        = coalesce(var.alerts.failed.no_data_state, var.defaults.no_data_state, "NoData")
        expr                 = "(sum(rate(nginx_ingress_controller_requests{status=~'5..|499', ${coalesce(var.alerts.failed.metric_filter, var.defaults.metric_filter)}}[${coalesce(var.alerts.failed.interval, var.defaults.interval)}])) by (host, path) / sum(rate(nginx_ingress_controller_requests{${coalesce(var.alerts.failed.metric_filter, var.defaults.metric_filter)}}[${coalesce(var.alerts.failed.interval, var.defaults.interval)}])) by (host, path)) * 100"
        pending_period       = coalesce(var.alerts.failed.pending_period, var.defaults.pending_period)
        function             = "last"
        equation             = "gt"
        threshold            = 100 - coalesce(var.alerts.failed.threshold_percent, var.defaults.threshold_percent)
        filters              = {}
        labels               = merge(var.defaults.labels, var.alerts.failed.labels)
        settings_mode        = "replaceNN"
        settings_replaceWith = 0
      }
    ] : [],
    module.nginx_service_alerts.alert_rules,
    []
  )
  description = "The generated alert rules"
}

module "nginx_service_alerts" {
  source = "../block-service"

  name      = var.name
  namespace = var.namespace

  defaults   = var.defaults
  alerts     = var.alerts
  datasource = var.datasource
}
