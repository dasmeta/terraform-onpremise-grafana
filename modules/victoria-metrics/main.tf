resource "helm_release" "victoria_metrics" {
  name             = var.release_name
  repository       = "https://victoriametrics.github.io/helm-charts"
  chart            = "victoria-metrics-cluster"
  namespace        = var.namespace
  create_namespace = var.create_namespace
  timeout          = 600
  version          = var.chart_version

  values = [
    jsonencode({
      vminsert = {
        replicaCount = var.configs.vminsert.replica_count
        extraArgs = {
          replicationFactor = 2
        }
      }
      vmselect = {
        replicaCount = var.configs.vmselect.replica_count
        extraArgs = {
          replicationFactor         = 2
          "dedup.minScrapeInterval" = "1ms"
          "search.skipSlowReplicas" = true
        }
      }
      vmstorage = {
        replicaCount    = var.configs.vmstorage.replica_count
        retentionPeriod = var.configs.retention_period
        persistentVolume = {
          enabled          = true
          storageClassName = var.configs.vmstorage.storage_class
          size             = var.configs.vmstorage.storage_size
          accessModes      = var.configs.vmstorage.access_modes
        }
      }
    }),
    jsonencode(var.extra_configs)
  ]
}
