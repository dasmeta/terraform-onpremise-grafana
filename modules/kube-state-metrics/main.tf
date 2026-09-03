resource "helm_release" "kube_state_metrics" {
  name             = var.release_name
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-state-metrics"
  namespace        = var.namespace
  create_namespace = var.create_namespace
  timeout          = 600
  version          = var.chart_version

  values = [
    jsonencode(var.extra_configs),
    jsonencode(local.selector_owned_values),
  ]
}
