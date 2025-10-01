module "base" {
  source = "../../base"

  name = "Volume Capacity"
  data_source = {
    type = "prometheus"
    uid  = var.datasource_uid
  }
  coordinates   = var.coordinates
  period        = var.period
  unit          = "bytes"
  legend_format = "{{${var.pvc_name != "" ? var.pvc_name : var.container}}}"

  metrics = [
    { label = "Allocated", color = "FFC300", legend_format = "Allocated({{persistentvolumeclaim}})", expression = "kubelet_volume_stats_capacity_bytes{persistentvolumeclaim=~\"${var.pvc_name != "" ? var.pvc_name : var.container}-.*\", namespace=\"${var.namespace}\"}" },
    { label = "Used", color = "FF774D", legend_format = "Used({{persistentvolumeclaim}})", expression = "kubelet_volume_stats_used_bytes{persistentvolumeclaim=~\"${var.pvc_name != "" ? var.pvc_name : var.container}-.*\", namespace=\"${var.namespace}\"}" },
  ]
}
