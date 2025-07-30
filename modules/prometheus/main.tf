# Deploy Prometheus
resource "helm_release" "prometheus" {

  name             = "prometheus"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  namespace        = var.namespace
  create_namespace = true
  timeout          = 600
  version          = var.chart_version

  values = [
    templatefile("${path.module}/values/prometheus-values.yaml.tpl", {
      retention_days     = var.configs.retention_days
      storage_class_name = var.configs.storage_class
      storage_size       = var.configs.storage_size
      access_modes       = var.configs.access_modes

      request_cpu = var.configs.resources.request.cpu
      request_mem = var.configs.resources.request.mem
      limit_cpu   = var.configs.resources.limit.cpu
      limit_mem   = var.configs.resources.limit.mem

      replicas = var.configs.replicas

      enable_alertmanager = var.configs.enable_alertmanager

      ingress_enabled     = var.configs.ingress.enabled
      ingress_class       = var.configs.ingress.type
      ingress_annotations = var.configs.ingress.annotations
      ingress_hosts       = var.configs.ingress.hosts
      ingress_paths       = var.configs.ingress.path
      tls_secrets         = local.ingress_tls
    })
  ]

}
