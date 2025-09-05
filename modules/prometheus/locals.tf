locals {

  default_kubelet_labels = ["container_cpu_.*", "container_memory_.*", "kube_pod_container_status_.*",
    "kube_pod_container_resource_*", "container_network_.*", "kube_pod_resource_limit",
    "kube_pod_resource_request", "pod_cpu_usage_seconds_total", "pod_memory_usage_bytes",
    "kubelet_volume_stats", "volume_operation_total_seconds"
  ]
  kubelet_labels = format("^(%s)$", join("|", length(var.configs.kubelet_labels) > 0 ? var.configs.kubelet_labels : local.default_kubelet_labels))


  ingress_annotations = merge(
    {
      "kubernetes.io/ingress.class" = var.configs.ingress.type
    },
    var.configs.ingress.type == "alb" ? merge({
      "alb.ingress.kubernetes.io/target-type"      = "ip"
      "alb.ingress.kubernetes.io/scheme"           = var.configs.ingress.public ? "internet-facing" : "internal"
      "alb.ingress.kubernetes.io/healthcheck-path" = "/api/health"
      "alb.ingress.kubernetes.io/listen-ports" = join(
        "",
        concat(
          ["["],
          [join(",", compact([
            "{\\\"HTTP\\\": 80}",
            var.configs.ingress.tls_enabled ? "{\\\"HTTPS\\\": 443}" : null
          ]))],
          ["]"]
        )
      )

      }, var.configs.ingress.tls_enabled ? {
      "alb.ingress.kubernetes.io/ssl-redirect" = "443"
      # "alb.ingress.kubernetes.io/certificate-arn" = var.configs.ingress.alb_certificate
    } : {}) : {},
    var.configs.ingress.type == "nginx" ? merge({
      "nginx.ingress.kubernetes.io/backend-protocol"   = "HTTP"
      "nginx.ingress.kubernetes.io/proxy-buffer-size"  = "128k"
      "nginx.ingress.kubernetes.io/proxy-read-timeout" = "60"
      "nginx.ingress.kubernetes.io/proxy-send-timeout" = "60"
      }, var.configs.ingress.tls_enabled ? {
      "nginx.ingress.kubernetes.io/ssl-redirect"       = "true"
      "nginx.ingress.kubernetes.io/force-ssl-redirect" = "true"
      # "cert-manager.io/cluster-issuer"                 = "letsencrypt-prod"
    } : {}) : {},
    var.configs.ingress.annotations
  )

  ingress_tls = var.configs.ingress.tls_enabled && var.configs.ingress.type == "nginx" ? [{
    hosts       = var.configs.ingress.hosts
    secret_name = join("-", [replace(var.configs.ingress.hosts[0], ".", "-"), "tls"])
  }] : []

}
