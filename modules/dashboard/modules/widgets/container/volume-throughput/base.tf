module "base" {
  source = "../../base"

  name = "Volume Throughput"
  data_source = {
    type = "prometheus"
    uid  = var.datasource_uid
  }
  coordinates = var.coordinates
  period      = var.period
  unit        = "bytes"


  metrics = [
    { label = "Read", expression = "sum(rate(container_fs_reads_bytes_total{pod=~\"${var.pod}-.*\", namespace=\"${var.namespace}\"}[${var.period}]))" },
    { label = "Write", expression = "-sum(rate(container_fs_writes_bytes_total{pod=~\"${var.pod}-.*\", namespace=\"${var.namespace}\"}[${var.period}]))" },
    { label = "Read ({{pod}})", expression = "sum(rate(container_fs_reads_bytes_total{pod=~\"${var.pod}-.*\", namespace=\"${var.namespace}\"}[${var.period}])) by (pod)" },
    { label = "Write ({{pod}})", expression = "-sum(rate(container_fs_writes_bytes_total{pod=~\"${var.pod}-.*\", namespace=\"${var.namespace}\"}[${var.period}])) by (pod)" },
  ]
}
