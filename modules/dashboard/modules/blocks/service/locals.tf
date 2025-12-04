locals {
  all_widgets = [for row_index, row in chunklist(concat(
    [
      { type : "container/cpu", container : var.name, datasource_uid = var.prometheus_datasource_uid, period = var.period },
      { type : "container/memory", container : var.name, datasource_uid = var.prometheus_datasource_uid, period = var.period },
      { type : "container/replicas", container : var.name, datasource_uid = var.prometheus_datasource_uid, period = var.period },
    ],
    [
      { type : "container/network", host : var.host, container : var.name, datasource_uid = var.prometheus_datasource_uid, period = var.period },
      { type : "container/network-error", host : var.host, pod : var.name, datasource_uid = var.prometheus_datasource_uid, period = var.period },
    ],
    var.host != null ? [
      { type : "container/request-count", host : var.host, container : var.name, datasource_uid = var.prometheus_datasource_uid, period = var.period },
      { type : "container/request-count", host : var.host, container : var.name, only_5xx : true, datasource_uid = var.prometheus_datasource_uid, period = var.period },
      { type : "container/response-time", host : var.host, container : var.name, datasource_uid = var.prometheus_datasource_uid, period = var.period },
    ] : [],
    var.disk_widgets.enabled ? concat([
      { type : "container/volume-iops", pod : var.name, datasource_uid = var.prometheus_datasource_uid, period = var.period },
      { type : "container/volume-throughput", pod : var.name, datasource_uid = var.prometheus_datasource_uid, period = var.period }
      ],
      [for pvc_name in var.disk_widgets.pvc_names : { type : "container/volume-capacity", container : var.name, datasource_uid = var.prometheus_datasource_uid, pvc_name = pvc_name, period = var.period }]
    ) : [],
    var.log_widgets.enabled ?
    concat([{ type : "deployment/logs-size", deployment : var.name, datasource_uid = var.loki_datasource_uid, error_filter = var.log_widgets.error_filter, warn_filter = var.log_widgets.warn_filter, period = var.period_loki }],
      var.log_widgets.show_logs ? [{ type : "deployment/warn-logs", datasource_uid = var.loki_datasource_uid, parser = var.log_widgets.parser, filter = var.log_widgets.warn_filter, direction = var.log_widgets.direction, limit = var.log_widgets.limit, period = var.period_loki },
        { type : "deployment/error-logs", deployment : var.name, datasource_uid = var.loki_datasource_uid, parser = var.log_widgets.parser, filter = var.log_widgets.error_filter, direction = var.log_widgets.direction, limit = var.log_widgets.limit, period = var.period_loki },
      { type : "deployment/latest-logs", deployment : var.name, datasource_uid = var.loki_datasource_uid, parser = var.log_widgets.parser, filter = var.log_widgets.latest_filter, direction = var.log_widgets.direction, limit = var.log_widgets.limit, period = var.period_loki }] : []
    ) : [],
    ), var.columns) : [for column_index, item in row : merge(item, {
      width     = floor(24 / length(row)),
      namespace = var.namespace
  })]]

  # all_widgets_positions_fixed = [for row_index, row in local.all_widgets : [for column_index, item in row : item]]
}
