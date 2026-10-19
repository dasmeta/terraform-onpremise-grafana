locals {
  common = {
    namespace      = var.namespace
    extra_filters  = var.extra_filters
    datasource_uid = var.datasource_uid
    period         = var.period
    width          = floor(24 / var.columns)
  }

  # ordered panel list per widget group, groups can be switched off with var.widgets
  panels = concat(
    var.widgets.nodes ? ["nodes"] : [],
    var.widgets.drift ? ["drifted-nodes", "drift-duration"] : [],
    var.widgets.nodes ? ["nodes-created-terminated", "nodes-not-initialized"] : [],
    var.widgets.disruption ? ["nodes-disrupted", "disruption-decisions"] : [],
    var.widgets.capacity ? ["pending-pods", "pod-wait", "nodepool-usage"] : [],
    var.widgets.cloud_provider ? ["cloudprovider-errors"] : [],
    var.widgets.interruption ? ["interruptions"] : [],
    var.widgets.controller ? ["reconcile-errors"] : [],
  )
}

output "result" {
  description = "Karpenter dashboard block widget rows"
  value = concat(
    [[{ type : "text/title-with-collapse", text : var.block_name }]],
    # var.columns widgets per line(grafana grid is 24 wide)
    [for row in chunklist(local.panels, var.columns) : [for panel in row : merge(local.common, { type : "karpenter/${panel}" })]],
  )
}
