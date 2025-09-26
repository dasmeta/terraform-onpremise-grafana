module "base" {
  source = "../../base"

  name = "Volume IOPS"
  data_source = {
    type = "prometheus"
    uid  = var.datasource_uid
  }
  coordinates = var.coordinates
  period      = var.period
  unit        = "iops"


  metrics = [
    { label = "Reads", color = "FFC300", legend_format = "Reads({{pod}})", expression = "container_fs_reads_total{pod=~\"${var.pod}-.*\", namespace=\"${var.namespace}\"}" },
    { label = "Writes", color = "FF774D", legend_format = "Writes({{pod}})", expression = "container_fs_writes_total{pod=~\"${var.pod}-.*\", namespace=\"${var.namespace}\"}" },
  ]
}
