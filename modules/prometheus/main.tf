# Deploy Prometheus
resource "helm_release" "prometheus" {

  name             = var.release_name
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  namespace        = var.namespace
  create_namespace = var.create_namespace
  timeout          = 600
  version          = var.chart_version

  values = [
    templatefile("${path.module}/values/prometheus-values.yaml.tpl", {
      retention_days     = var.configs.retention_days
      storage_class_name = var.configs.storage_class
      storage_size       = var.configs.storage_size
      access_modes       = var.configs.access_modes

      request_cpu = var.configs.resources.requests.cpu
      request_mem = var.configs.resources.requests.memory
      limit_cpu   = var.configs.resources.limits.cpu
      limit_mem   = var.configs.resources.limits.memory

      replicas                     = var.configs.replicas
      additional_scrape_configs    = var.configs.additional_scrape_configs
      additional_args              = var.configs.additional_args
      enable_alertmanager          = var.configs.enable_alertmanager
      scrape_helm_chart_components = var.configs.scrape_helm_chart_components
      kubelet_labels               = local.kubelet_labels

      ingress_enabled     = var.configs.ingress.enabled
      ingress_class       = var.configs.ingress.type
      ingress_annotations = local.ingress_annotations
      ingress_hosts       = var.configs.ingress.hosts
      ingress_paths       = var.configs.ingress.path
      tls_secrets         = local.ingress_tls
      ingress_path_type   = var.configs.ingress.path_type
    }),
    jsonencode(var.extra_configs)
  ]

}
