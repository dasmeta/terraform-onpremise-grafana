output "result" {
  description = "description"
  value = [
    [
      { type : "text/title-with-collapse", text : "Nginx Ingress Controller" }
    ],
    [
      { type : "ingress/request-rate", filter = var.filter, datasource_uid = var.datasource_uid },
      { type : "ingress/connections", filter = var.filter, datasource_uid = var.datasource_uid },
      { type : "ingress/latency", filter = var.filter, datasource_uid = var.datasource_uid },
      { type : "ingress/latency", filter = var.filter, by_host : true, datasource_uid = var.datasource_uid },
    ],
    [
      { type : "ingress/request-count", filter = var.filter, datasource_uid = var.datasource_uid },
      { type : "ingress/request-count", filter = var.filter, only_5xx : true, datasource_uid = var.datasource_uid },
      { type : "ingress/request-count", filter = var.filter, only_5xx : true, by_path : true, datasource_uid = var.datasource_uid },
      { type : "ingress/request-count", filter = var.filter, only_5xx : true, by_status_path : true, datasource_uid = var.datasource_uid },
    ],
    [
      { type : "ingress/cpu", pod : var.pod, namespace : var.namespace, datasource_uid = var.datasource_uid },
      { type : "ingress/memory", pod : var.pod, namespace : var.namespace, datasource_uid = var.datasource_uid },
      { type : "container/network-traffic", pod : "(.+-)?${var.pod}", filter = var.filter, namespace : var.namespace, datasource_uid = var.datasource_uid },
      { type : "container/network-error", pod : "(.+-)?${var.pod}", filter = var.filter, namespace : var.namespace, datasource_uid = var.datasource_uid },
    ],
  ]
}
