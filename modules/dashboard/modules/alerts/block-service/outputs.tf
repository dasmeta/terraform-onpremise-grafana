output "alert_rules" {
  value = concat(
    coalesce(local.alerts.replicas_no.enabled, local.defaults.enabled, false) ? [
      {
        name           = "`${var.namespace}/${var.name}` service has no any running replica/pod"
        folder_name    = try(coalesce(local.alerts.replicas_no.folder_name, local.defaults.folder_name), null)
        summary        = "{{ .Labels.alertname }} it is already ${coalesce(local.alerts.replicas_no.pending_period, local.defaults.pending_period)}"
        group          = try(coalesce(local.alerts.replicas_no.group, local.defaults.group), "${var.namespace}/${var.name} service")
        datasource     = var.datasource
        no_data_state  = coalesce(local.alerts.replicas_no.no_data_state, local.defaults.no_data_state, "NoData")
        exec_err_state = coalesce(local.alerts.replicas_no.exec_err_state, local.defaults.exec_err_state, "Error")
        expr           = local.defaults.replicas_count_expr
        pending_period = coalesce(local.alerts.replicas_no.pending_period, local.defaults.pending_period)
        function       = "last"
        equation       = "lte"
        threshold      = 0
        filters        = {}
        labels         = merge(local.defaults.labels, local.alerts.replicas_no.labels)
        annotations = merge({
          "threshold" = 0,
          "metric"    = "replicas",
          "impact"    = "Service will go down"
          "component" = "pod"
          "resource"  = "deployment"
        }, try(local.alerts.replicas_no.annotations, {}))
        settings_mode        = "replaceNN"
        settings_replaceWith = 0
      }
    ] : [],
    coalesce(local.alerts.replicas_max.enabled, local.defaults.enabled, false) ? [
      {
        name           = "`${var.namespace}/${var.name}` service has reached to its max ${local.alerts.replicas_max.threshold != null ? local.alerts.replicas_max.threshold : "hpa"} replicas/pods"
        folder_name    = try(coalesce(local.alerts.replicas_max.folder_name, local.defaults.folder_name), null)
        summary        = "{{ .Labels.alertname }} count it is already ${coalesce(local.alerts.replicas_max.pending_period, local.defaults.pending_period)}"
        group          = try(coalesce(local.alerts.replicas_max.group, local.defaults.group), "${var.namespace}/${var.name} service")
        no_data_state  = coalesce(local.alerts.replicas_max.no_data_state, local.defaults.no_data_state, "NoData")
        exec_err_state = coalesce(local.alerts.replicas_max.exec_err_state, local.defaults.exec_err_state, "Error")
        datasource     = var.datasource
        expr           = "${local.alerts.replicas_max.threshold != null ? "${local.alerts.replicas_max.threshold} -" : "(kube_horizontalpodautoscaler_spec_max_replicas{namespace='${var.namespace}', horizontalpodautoscaler='${var.name}'}) - on(namespace) group_left(${local.defaults.workload_type})"} (${local.defaults.replicas_count_expr})"
        pending_period = coalesce(local.alerts.replicas_max.pending_period, local.defaults.pending_period)
        function       = "last"
        equation       = "lte"
        threshold      = 0
        filters        = {}
        labels         = merge(local.defaults.labels, local.alerts.replicas_max.labels)
        annotations = merge({
          "threshold" = 0,
          "metric"    = "replicas",
          "impact"    = "Service might response slower"
          "component" = "pod"
          "resource"  = "deployment"
        }, try(local.alerts.replicas_max.annotations, {}), { for k, v in try(local.alerts.annotations, {}) : k => v if length(v) > 0 })
        settings_mode        = "replaceNN"
        settings_replaceWith = 0
      }
    ] : [],
    coalesce(local.alerts.replicas_min.enabled, local.defaults.enabled, false) ? [
      {
        name           = "`${var.namespace}/${var.name}` service has less than min ${local.alerts.replicas_min.threshold != null ? local.alerts.replicas_min.threshold : "hpa"} replicas/pods"
        summary        = "{{ .Labels.alertname }} it is already ${coalesce(local.alerts.replicas_min.pending_period, local.defaults.pending_period)}"
        group          = try(coalesce(local.alerts.replicas_min.group, local.defaults.group), "${var.namespace}/${var.name} service")
        no_data_state  = coalesce(local.alerts.replicas_min.no_data_state, local.defaults.no_data_state, "NoData")
        exec_err_state = coalesce(local.alerts.replicas_min.exec_err_state, local.defaults.exec_err_state, "Error")
        datasource     = var.datasource
        expr           = "(${local.defaults.replicas_count_expr}) - on(namespace) group_right(${local.defaults.workload_type}) ${local.alerts.replicas_min.threshold != null ? "${local.alerts.replicas_min.threshold}" : "(kube_horizontalpodautoscaler_spec_min_replicas{namespace='${var.namespace}', horizontalpodautoscaler='${var.name}'})"}"
        pending_period = coalesce(local.alerts.replicas_min.pending_period, local.defaults.pending_period)
        function       = "last"
        equation       = "lt"
        threshold      = 0
        filters        = {}
        labels         = merge(local.defaults.labels, local.alerts.replicas_min.labels)
        annotations = merge({ for k, v in try(local.alerts.annotations, {}) : k => v if length(v) > 0 },
          {
            "threshold" = 0,
            "metric"    = "replicas",
            "impact"    = "Service might go down"
            "component" = "pod"
            "resource"  = "deployment"
          },
        try(local.alerts.replicas_min.annotations, {}))
        settings_mode        = "replaceNN"
        settings_replaceWith = 0
      }
    ] : [],
    coalesce(local.alerts.replicas_state.enabled, local.defaults.enabled, false) ? [
      {
        name           = "`${var.namespace}/${var.name}` service has Failed/Pending/Unknown status/phase replicas/pods"
        summary        = "{{ .Labels.alertname }} it is already ${coalesce(local.alerts.replicas_state.pending_period, local.defaults.pending_period)}"
        group          = try(coalesce(local.alerts.replicas_state.group, local.defaults.group), "${var.namespace}/${var.name} service")
        no_data_state  = coalesce(local.alerts.replicas_state.no_data_state, local.defaults.no_data_state, "NoData")
        exec_err_state = coalesce(local.alerts.replicas_state.exec_err_state, local.defaults.exec_err_state, "Error")
        datasource     = var.datasource
        expr           = "sum(kube_pod_status_phase{namespace='${var.namespace}', pod=~'^${var.defaults.workload_prefix}${var.name}${var.defaults.workload_suffix}(-[^-]+)?-[^-]+$', phase!='Succeeded', phase!='Running'}) by (phase)"
        pending_period = coalesce(local.alerts.replicas_state.pending_period, local.defaults.pending_period)
        function       = "last"
        equation       = "gte"
        threshold      = local.alerts.replicas_state.threshold
        filters        = {}
        labels         = merge(local.defaults.labels, local.alerts.replicas_state.labels)
        annotations = merge({ for k, v in try(local.alerts.annotations, {}) : k => v if length(v) > 0 },
          {
            "threshold" = local.alerts.replicas_state.threshold,
            "metric"    = "replicas",
            "impact"    = "Service might become unresponsive or go down"
            "component" = "pod"
            "resource"  = "deployment"
        }, try(local.alerts.replicas_state.annotations, {}))
        settings_mode        = "replaceNN"
        settings_replaceWith = 0
      }
    ] : [],
    coalesce(local.alerts.job_failed.enabled, local.defaults.enabled, false) ? [
      {
        name           = "`${var.namespace}/${var.name}` job/cronjob has failed replicas/pods"
        summary        = "{{ .Labels.alertname }} it is already ${coalesce(local.alerts.job_failed.pending_period, local.defaults.pending_period)}"
        group          = try(coalesce(local.alerts.job_failed.group, local.defaults.group), "${var.namespace}/${var.name} service")
        no_data_state  = coalesce(local.alerts.job_failed.no_data_state, local.defaults.no_data_state, "NoData")
        exec_err_state = coalesce(local.alerts.job_failed.exec_err_state, local.defaults.exec_err_state, "Error")
        datasource     = var.datasource
        expr           = "sum(kube_job_status_failed{namespace='${var.namespace}', job_name=~'${var.defaults.workload_prefix}${var.name}${var.defaults.workload_suffix}-[^-]+$'}) by (reason)"
        pending_period = coalesce(local.alerts.job_failed.pending_period, local.defaults.pending_period)
        function       = "last"
        equation       = "gte"
        threshold      = local.alerts.job_failed.threshold
        filters        = {}
        labels         = merge(local.defaults.labels, local.alerts.job_failed.labels)
        annotations = merge({ for k, v in try(local.alerts.annotations, {}) : k => v if length(v) > 0 },
          {
            "threshold" = local.alerts.job_failed.threshold,
            "metric"    = "replicas",
            "impact"    = "Jobs not being executed"
            "component" = "pod"
            "resource"  = "deployment"
        }, try(local.alerts.job_failed.annotations, {}))
        settings_mode        = "replaceNN"
        settings_replaceWith = 0
      }
    ] : [],
    coalesce(local.alerts.restarts.enabled, local.defaults.enabled, false) ? [
      {
        name            = "`${var.namespace}/${var.name}` service has too many restarts for ${coalesce(local.alerts.restarts.interval, local.defaults.interval)} interval"
        group           = try(coalesce(local.alerts.restarts.group, local.defaults.group), "${var.namespace}/${var.name} service")
        no_data_state   = coalesce(local.alerts.restarts.no_data_state, local.defaults.no_data_state, "NoData")
        exec_err_state  = coalesce(local.alerts.restarts.exec_err_state, local.defaults.exec_err_state, "Error")
        datasource      = var.datasource
        metric_name     = "kube_pod_container_status_restarts_total"
        metric_function = "increase"
        metric_interval = "[${coalesce(local.alerts.restarts.interval, local.defaults.interval)}]"
        filters = {
          namespace = var.namespace
          container = var.name
        }
        function  = "last"
        equation  = "gte"
        threshold = local.alerts.restarts.threshold
        labels    = merge(local.defaults.labels, local.alerts.restarts.labels)
        annotations = merge({ for k, v in try(local.alerts.annotations, {}) : k => v if length(v) > 0 },
          {
            "threshold" = local.alerts.restarts.threshold,
            "metric"    = "replicas",
            "impact"    = "Service will go down"
            "component" = "pod"
            "resource"  = "deployment"
        }, try(local.alerts.restarts.annotations, {}))
        settings_mode        = "replaceNN"
        settings_replaceWith = 0
      }
    ] : [],
    coalesce(local.alerts.network_in.enabled, local.defaults.enabled, false) ? [
      {
        name           = "`${var.namespace}/${var.name}` service has anomaly increase of in/receive network traffic for ${coalesce(local.alerts.network_in.interval, local.defaults.interval)} interval"
        summary        = "{{ .Labels.alertname }} it is already ${coalesce(local.alerts.network_in.pending_period, local.defaults.pending_period)}"
        group          = try(coalesce(local.alerts.network_in.group, local.defaults.group), "${var.namespace}/${var.name} service")
        no_data_state  = coalesce(local.alerts.network_in.no_data_state, local.defaults.no_data_state, "NoData")
        exec_err_state = coalesce(local.alerts.network_in.exec_err_state, local.defaults.exec_err_state, "Error")
        datasource     = var.datasource
        expr           = "abs(sum(rate(container_network_receive_bytes_total{pod=~'^${var.defaults.workload_prefix}${var.name}${var.defaults.workload_suffix}(-[^-]+)?-[^-]+$', namespace='${var.namespace}'}[${coalesce(local.alerts.network_in.interval, local.defaults.interval)}])) by (namespace) / (sum(rate(container_network_receive_bytes_total{pod=~'^${var.defaults.workload_prefix}${var.name}${var.defaults.workload_suffix}(-[^-]+)?-[^-]+$', namespace='${var.namespace}'}[${coalesce(local.alerts.network_in.interval, local.defaults.interval)}] offset ${coalesce(local.alerts.network_in.interval, local.defaults.interval)})) by (namespace) > 0) - 1)"
        pending_period = coalesce(local.alerts.network_in.pending_period, local.defaults.pending_period)
        function       = "last"
        filters        = {}
        equation       = "gte"
        threshold      = coalesce(local.alerts.network_in.deviation, local.defaults.deviation)
        labels         = merge(local.defaults.labels, local.alerts.network_in.labels)
        annotations = merge({ for k, v in try(local.alerts.annotations, {}) : k => v if length(v) > 0 },
          {
            "threshold" = coalesce(local.alerts.network_in.deviation, local.defaults.deviation),
            "metric"    = "replicas",
            "impact"    = "Service will go down"
            "component" = "pod"
            "resource"  = "deployment"
        }, try(local.alerts.network_in.annotations, {}))
        settings_mode        = "replaceNN"
        settings_replaceWith = 0
      }
    ] : [],
    coalesce(local.alerts.network_out.enabled, local.defaults.enabled, false) ? [
      {
        name           = "`${var.namespace}/${var.name}` service has anomaly increase of out/transmit network traffic for ${coalesce(local.alerts.network_out.interval, local.defaults.interval)} interval"
        summary        = "{{ .Labels.alertname }} it is already ${coalesce(local.alerts.network_out.pending_period, local.defaults.pending_period)}"
        group          = try(coalesce(local.alerts.network_out.group, local.defaults.group), "${var.namespace}/${var.name} service")
        no_data_state  = coalesce(local.alerts.network_out.no_data_state, local.defaults.no_data_state, "NoData")
        exec_err_state = coalesce(local.alerts.network_out.exec_err_state, local.defaults.exec_err_state, "Error")
        datasource     = var.datasource
        expr           = "abs(sum(rate(container_network_transmit_bytes_total{pod=~'^${var.defaults.workload_prefix}${var.name}${var.defaults.workload_suffix}(-[^-]+)?-[^-]+$', namespace='${var.namespace}'}[${coalesce(local.alerts.network_out.interval, local.defaults.interval)}])) by (namespace) / (sum(rate(container_network_transmit_bytes_total{pod=~'^${var.defaults.workload_prefix}${var.name}${var.defaults.workload_suffix}(-[^-]+)?-[^-]+$', namespace='${var.namespace}'}[${coalesce(local.alerts.network_out.interval, local.defaults.interval)}] offset ${coalesce(local.alerts.network_out.interval, local.defaults.interval)})) by (namespace) > 0) - 1)"
        pending_period = coalesce(local.alerts.network_out.pending_period, local.defaults.pending_period)
        function       = "last"
        filters        = {}
        equation       = "gte"
        threshold      = coalesce(local.alerts.network_out.deviation, local.defaults.deviation)
        labels         = merge(local.defaults.labels, local.alerts.network_out.labels)
        annotations = merge({ for k, v in try(local.alerts.annotations, {}) : k => v if length(v) > 0 },
          {
            "threshold" = coalesce(local.alerts.network_out.deviation, local.defaults.deviation),
            "metric"    = "replicas",
            "impact"    = "Service will go down"
            "component" = "pod"
            "resource"  = "deployment"
        }, try(local.alerts.network_out.annotations, {}))
        settings_mode        = "replaceNN"
        settings_replaceWith = 0
      }
    ] : [],
    coalesce(local.alerts.cpu.enabled, local.defaults.enabled, false) ? [
      {
        name           = "`${var.namespace}/${var.name}` service has pods with cpu overloaded for ${coalesce(local.alerts.cpu.interval, local.defaults.interval)} interval"
        summary        = "{{ .Labels.alertname }} it is already ${coalesce(local.alerts.cpu.pending_period, local.defaults.pending_period)}"
        group          = try(coalesce(local.alerts.cpu.group, local.defaults.group), "${var.namespace}/${var.name} service")
        no_data_state  = coalesce(local.alerts.cpu.no_data_state, local.defaults.no_data_state, "NoData")
        exec_err_state = coalesce(local.alerts.cpu.exec_err_state, local.defaults.exec_err_state, "Error")
        datasource     = var.datasource
        expr           = "(max(rate(container_cpu_usage_seconds_total{container='${var.name}', namespace='${var.namespace}'}[${coalesce(local.alerts.cpu.interval, local.defaults.interval)}])) by (pod) / ${local.alerts.cpu.threshold != null ? "${local.alerts.cpu.threshold}" : "max(kube_pod_container_resource_${local.alerts.cpu.threshold_resource}{container='${var.name}', namespace='${var.namespace}', resource='cpu'}) by (pod)"}) * 100"
        pending_period = coalesce(local.alerts.cpu.pending_period, local.defaults.pending_period)
        function       = "last"
        filters        = {}
        equation       = "gte"
        threshold      = coalesce(local.alerts.cpu.threshold_percent, local.defaults.threshold_percent)
        labels         = merge(local.defaults.labels, local.alerts.cpu.labels)
        annotations = merge({ for k, v in try(local.alerts.annotations, {}) : k => v if length(v) > 0 },
          {
            "threshold" = coalesce(local.alerts.cpu.threshold_percent, local.defaults.threshold_percent),
            "metric"    = "cpu",
            "impact"    = "Service performance degraded"
            "component" = "pod"
            "resource"  = "deployment"
          },
          try(local.alerts.cpu.annotations, {})
        )
        settings_mode        = "replaceNN"
        settings_replaceWith = 0
      }
    ] : [],
    coalesce(local.alerts.memory.enabled, local.defaults.enabled, false) ? [
      {
        name           = "`${var.namespace}/${var.name}` service has pods with memory overloaded"
        summary        = "{{ .Labels.alertname }} it is already ${coalesce(local.alerts.memory.pending_period, local.defaults.pending_period)}"
        group          = try(coalesce(local.alerts.memory.group, local.defaults.group), "${var.namespace}/${var.name} service")
        no_data_state  = coalesce(local.alerts.memory.no_data_state, local.defaults.no_data_state, "NoData")
        exec_err_state = coalesce(local.alerts.memory.exec_err_state, local.defaults.exec_err_state, "Error")
        datasource     = var.datasource
        expr           = "(sum(container_memory_usage_bytes{container='${var.name}', namespace='${var.namespace}'}) by (pod) / ${local.alerts.memory.threshold != null ? "(${local.alerts.memory.threshold} * 1048576 )" : "max(kube_pod_container_resource_${local.alerts.memory.threshold_resource}{container='${var.name}', namespace='${var.namespace}', resource='memory'}) by (pod)"}) * 100"
        pending_period = coalesce(local.alerts.memory.pending_period, local.defaults.pending_period)
        function       = "last"
        filters        = {}
        equation       = "gte"
        threshold      = coalesce(local.alerts.memory.threshold_percent, local.defaults.threshold_percent)
        labels         = merge(local.defaults.labels, local.alerts.memory.labels)
        annotations = merge({ for k, v in try(local.alerts.annotations, {}) : k => v if length(v) > 0 },
          {
            "threshold" = coalesce(local.alerts.memory.threshold_percent, local.defaults.threshold_percent),
            "metric"    = "memory",
            "impact"    = "Service performance degraded"
            "component" = "pod"
            "resource"  = "deployment"
          },
          try(local.alerts.memory.annotations, {})
        )
        settings_mode        = "replaceNN"
        settings_replaceWith = 0
      }
    ] : [],
    []
  )
  description = "The generated alert rules"
}
