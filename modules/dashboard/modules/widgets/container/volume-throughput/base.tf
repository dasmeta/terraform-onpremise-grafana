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
    { label = "Bytes Read", color = "FFC300", legend_format = "Bytes Read({{pod}})", expression = "container_fs_reads_bytes_total{pod=~\"${var.pod}-.*\", namespace=\"${var.namespace}\"}" },
    { label = "Bytes Write", color = "FF774D", legend_format = "Bytes Write({{pod}})", expression = "container_fs_writes_bytes_total{pod=~\"${var.pod}-.*\", namespace=\"${var.namespace}\"}" },
  ]
}
