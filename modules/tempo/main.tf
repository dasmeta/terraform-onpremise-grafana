resource "helm_release" "tempo" {
  name             = "tempo"
  repository       = "https://grafana.github.io/helm-charts"
  chart            = "tempo"
  version          = var.chart_version
  namespace        = var.namespace
  create_namespace = true

  values = [
    templatefile("${path.module}/values/tempo-values.yaml.tpl", {
      storage_backend_type           = var.configs.storage.backend
      storage_backend_configurations = yamlencode(var.configs.storage.backend_configuration)

      persistence_enabled = var.configs.persistence.enabled
      persistence_size    = var.configs.persistence.size
      persistence_class   = var.configs.persistence.storage_class

      metris_generator_enabled     = var.configs.metrics_generator.enabled
      metrics_generator_remote_url = var.configs.metrics_generator.remote_url

      enable_service_monitor = var.configs.enable_service_monitor

      service_account_name        = var.configs.service_account.name
      service_account_annotations = var.configs.service_account.annotations
    })
  ]
}
