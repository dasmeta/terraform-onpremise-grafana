output "result" {
  description = "description"
  value = [
    [
      { type : "text/title-with-collapse", text : var.name }
    ],
    [
      { type : "container/cpu", container : var.name, namespace : var.namespace, datasource_uid = var.datasource_uid },
      { type : "container/memory", container : var.name, namespace : var.namespace, datasource_uid = var.datasource_uid },
      { type : "deployment/replicas", deployment : var.name, namespace : var.namespace, datasource_uid = var.datasource_uid },
      { type : "pod/restarts", pod : var.name, namespace : var.namespace, datasource_uid = var.datasource_uid },
    ],
    concat(
      [
        { type : "container/network", host : var.host, container : var.name, namespace : var.namespace, width : var.host != null ? 6 : 24, datasource_uid = var.datasource_uid },
        { type : "container/network-transmit", host : var.host, pod : var.name, namespace : var.namespace, width : var.host != null ? 6 : 24, datasource_uid = var.datasource_uid },
      ],
      var.host != null ? [
        { type : "container/request-count", host : var.host, container : var.name, namespace : var.namespace, width : 4, datasource_uid = var.datasource_uid },
        { type : "container/request-count", host : var.host, container : var.name, namespace : var.namespace, only_5xx : true, width : 4, datasource_uid = var.datasource_uid },
        { type : "container/response-time", host : var.host, container : var.name, namespace : var.namespace, width : 4, datasource_uid = var.datasource_uid },
      ] : [],
    ),
  ]
}
