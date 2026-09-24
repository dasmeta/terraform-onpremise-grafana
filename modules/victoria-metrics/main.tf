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
          replicationFactor      = 2
          maxLabelsPerTimeseries = 60
        }
        resources = {
          requests = {
            cpu    = "500m"
            memory = "512Mi"
          }
          limits = {
            cpu    = "2"
            memory = "1Gi"
          }
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
        resources = {
          requests = {
            cpu    = "500m"
            memory = "1Gi"
          }
          limits = {
            cpu    = "1"
            memory = "2Gi"
          }
        }
        persistentVolume = {
          enabled          = true
          storageClassName = var.configs.vmstorage.storage_class
          size             = var.configs.vmstorage.storage_size
          accessModes      = var.configs.vmstorage.access_modes
        }
      }
    }),
    jsonencode(var.extra_configs),
    jsonencode(local.cluster_endpoint_contract),
  ]

  lifecycle {
    precondition {
      condition     = !var.agent_enabled || var.operator_enabled
      error_message = "operator_enabled=true is required when agent_enabled=true."
    }
  }
}

resource "helm_release" "victoria_metrics_operator" {
  count = var.operator_enabled ? 1 : 0

  name             = var.operator_release_name
  repository       = "https://victoriametrics.github.io/helm-charts"
  chart            = "victoria-metrics-operator"
  namespace        = var.namespace
  create_namespace = var.create_namespace
  timeout          = 600
  version          = var.operator_chart_version

  values = [
    jsonencode(var.operator_extra_configs),
    jsonencode(local.operator_selector_owned_values),
  ]

  depends_on = [helm_release.victoria_metrics]
}

resource "helm_release" "victoria_metrics_resources" {
  count = var.operator_enabled ? 1 : 0

  name             = "${var.operator_release_name}-resources"
  chart            = "${path.module}/charts/resources"
  namespace        = var.namespace
  create_namespace = false
  timeout          = 600

  values = [
    jsonencode({ objects = local.operator_objects }),
  ]

  depends_on = [helm_release.victoria_metrics_operator]
}
