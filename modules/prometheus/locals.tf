locals {
  kubelet_labels = format("^(%s)$", join("|", var.configs.kubelet_metrics))

  ingress_annotations = merge(
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

  caller_extra_configs = (
    var.extra_configs == null
    ? tomap({})
    : merge({}, var.extra_configs)
  )
  caller_prometheus_values = try(
    merge({}, local.caller_extra_configs.prometheus),
    tomap({}),
  )
  caller_prometheus_spec = try(
    merge({}, local.caller_prometheus_values.prometheusSpec),
    tomap({}),
  )
  effective_prometheus_spec = merge(
    local.caller_prometheus_spec,
    var.remote_write_url == null ? {} : {
      remoteWrite = [{
        url = var.remote_write_url
      }]
    },
  )
  effective_extra_configs = merge(
    local.caller_extra_configs,
    {
      prometheus = merge(
        local.caller_prometheus_values,
        { prometheusSpec = local.effective_prometheus_spec },
      )
    },
  )

}
