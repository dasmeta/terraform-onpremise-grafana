# Deploy Prometheus
resource "helm_release" "prometheus" {

  name             = "prometheus"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  namespace        = var.namespace
  create_namespace = true
  timeout          = 600

  values = [
    templatefile("${path.module}/values/prometheus-values.yaml.tpl", {
      retention_days     = var.configs.retention_days
      storage_class_name = var.configs.storage_class
      storage_size       = var.configs.storage_size

      request_cpu = var.configs.resources.request.cpu
      request_mem = var.configs.resources.request.mem
      limit_cpu   = var.configs.resources.limit.cpu
      limit_mem   = var.configs.resources.limit.mem

      enable_alertmanager = var.configs.enable_alertmanager
    })
  ]

}
