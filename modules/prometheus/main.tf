# Deploy Prometheus
resource "helm_release" "prometheus" {

  name             = var.release_name
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  namespace        = var.namespace
  create_namespace = var.create_namespace
  timeout          = 600
  version          = var.chart_version

  values = [jsonencode(local.effective_values)]

}
