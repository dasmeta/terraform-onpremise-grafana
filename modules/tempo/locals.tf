locals {
  effective_metrics_generator_remote_url = coalesce(
    var.metrics_generator_remote_url,
    try(var.configs.metrics_generator.remote_url, null),
    "http://prometheus-kube-prometheus-prometheus.monitoring.svc.cluster.local:9090/api/v1/write",
  )
  effective_service_monitor_enabled = coalesce(
    var.service_monitor_enabled,
    try(var.configs.enable_service_monitor, false),
  )

  selector_owned_values = {
    tempo = {
      metricsGenerator = {
        remoteWriteUrl = local.effective_metrics_generator_remote_url
      }
    }
    serviceMonitor = {
      enabled = local.effective_service_monitor_enabled
    }
  }

  generated_values = yamldecode(templatefile("${path.module}/values/tempo-values.yaml.tpl", {
    storage_backend_type           = var.configs.storage.backend
    storage_backend_configurations = yamlencode(var.configs.storage.backend_configuration)

    persistence_enabled = var.configs.persistence.enabled
    persistence_size    = var.configs.persistence.size
    persistence_class   = var.configs.persistence.storage_class

    metrics_generator_enabled    = var.configs.metrics_generator.enabled
    metrics_generator_remote_url = local.effective_metrics_generator_remote_url

    enable_service_monitor = local.effective_service_monitor_enabled

    service_account_name        = var.configs.service_account.name
    service_account_annotations = var.configs.service_account.annotations
  }))

  effective_values = provider::deepmerge::mergo(
    provider::deepmerge::mergo(
      local.generated_values,
      yamldecode(jsonencode(var.extra_configs)),
    ),
    local.selector_owned_values,
  )
}
