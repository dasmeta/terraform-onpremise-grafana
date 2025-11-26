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
    { label = "Reads", expression = "sum(rate(container_fs_reads_total{pod=~\"${var.pod}-.*\", namespace=\"${var.namespace}\"}[${var.period}]))" },
    { label = "Writes", expression = "-sum(rate(container_fs_writes_total{pod=~\"${var.pod}-.*\", namespace=\"${var.namespace}\"}[${var.period}]))" },
    { label = "Reads ({{pod}})", expression = "sum(rate(container_fs_reads_total{pod=~\"${var.pod}-.*\", namespace=\"${var.namespace}\"}[${var.period}])) by (pod)" },
    { label = "Writes ({{pod}})", expression = "-sum(rate(container_fs_writes_total{pod=~\"${var.pod}-.*\", namespace=\"${var.namespace}\"}[${var.period}])) by (pod)" },
  ]
}
