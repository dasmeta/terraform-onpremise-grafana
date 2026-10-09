resource "helm_release" "tempo" {
  name             = var.release_name
  repository       = "https://grafana.github.io/helm-charts"
  chart            = "tempo"
  version          = var.chart_version
  namespace        = var.namespace
  create_namespace = var.create_namespace

  values = [jsonencode(local.effective_values)]
}
