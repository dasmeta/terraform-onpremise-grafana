locals {
  all_widgets = [for row_index, row in chunklist(concat(
    [
      { type : "container/cpu", container : var.name, namespace = var.namespace, datasource_uid = var.prometheus_datasource_uid },
      { type : "container/memory", container : var.name, namespace = var.namespace, datasource_uid = var.prometheus_datasource_uid },
      { type : "container/replicas", container : var.name, namespace = var.namespace, datasource_uid = var.prometheus_datasource_uid },
    ],
    [
      { type : "container/network", host : var.host, container : var.name, namespace = var.namespace, datasource_uid = var.prometheus_datasource_uid },
      { type : "container/network-error", host : var.host, pod : var.name, namespace = var.namespace, datasource_uid = var.prometheus_datasource_uid },
    ],
    var.host != null ? [
      { type : "container/request-count", host : var.host, container : var.name, namespace = var.namespace, datasource_uid = var.prometheus_datasource_uid },
      { type : "container/request-count", host : var.host, container : var.name, namespace = var.namespace, only_5xx : true, datasource_uid = var.prometheus_datasource_uid },
      { type : "container/response-time", host : var.host, container : var.name, namespace = var.namespace, datasource_uid = var.prometheus_datasource_uid },
    ] : [],
    var.disk_widgets.enabled ? concat([
      { type : "container/volume-iops", pod : var.name, namespace = var.namespace, datasource_uid = var.prometheus_datasource_uid },
      { type : "container/volume-throughput", pod : var.name, namespace = var.namespace, datasource_uid = var.prometheus_datasource_uid }
      ],
      [for pvc_name in var.disk_widgets.pvc_names : { type : "container/volume-capacity", container : var.name, namespace = var.namespace, datasource_uid = var.prometheus_datasource_uid, pvc_name = pvc_name }]
    ) : [],
    var.log_widgets.enabled ?
    concat([{ type : "deployment/logs-size", deployment : var.name, namespace = var.namespace, datasource_uid = var.loki_datasource_uid, error_filter = var.log_widgets.error_filter, warn_filter = var.log_widgets.warn_filter }],
      var.log_widgets.show_logs ? [{ type : "deployment/warn-logs", deployment : var.name, namespace = var.namespace, datasource_uid = var.loki_datasource_uid, parser = var.log_widgets.parser, filter = var.log_widgets.warn_filter, direction = var.log_widgets.direction, limit = var.log_widgets.limit },
        { type : "deployment/error-logs", deployment : var.name, namespace = var.namespace, datasource_uid = var.loki_datasource_uid, parser = var.log_widgets.parser, filter = var.log_widgets.error_filter, direction = var.log_widgets.direction, limit = var.log_widgets.limit },
      { type : "deployment/latest-logs", deployment : var.name, namespace = var.namespace, datasource_uid = var.loki_datasource_uid, parser = var.log_widgets.parser, filter = var.log_widgets.latest_filter, direction = var.log_widgets.direction, limit = var.log_widgets.limit }] : []
    ) : [],
  ), var.columns) : [for column_index, item in row : merge(item, { width = floor(24 / length(row)) })]]

  all_widgets_positions_fixed = [for row_index, row in local.all_widgets : [for column_index, item in row : item]]
}
