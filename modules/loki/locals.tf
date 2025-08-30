locals {
  # Promtail related configs
  default_promtail_pipelines_stages = [{ cri = {} }]
  extra_relabel_configs = concat(
    try(var.configs.promtail.extra_relabel_configs, []),
    length(var.configs.promtail.ignored_namespaces) > 0 ?
    [{
      action        = "drop"
      source_labels = ["__meta_kubernetes_namespace"]
      regex         = format("(%s)", join("|", var.configs.promtail.ignored_namespaces))
    }] :
    [],
    length(var.configs.promtail.ignored_containers) > 0 ?
    [{
      action        = "drop"
      source_labels = ["__meta_kubernetes_pod_container_name"]
      regex         = format("(%s)", join("|", var.configs.promtail.ignored_containers))
    }] :
    []
  )
  extra_relabel_configs_yaml = yamlencode(local.extra_relabel_configs)
  extra_scrape_configs_yaml  = length(var.configs.promtail.extra_scrape_configs) > 0 ? yamlencode(var.configs.promtail.extra_scrape_configs) : ""
  extra_pipeline_stages_yaml = yamlencode(concat(local.default_promtail_pipelines_stages, var.configs.promtail.extra_pipeline_stages))

  # Loki configs
  limits_config = merge(var.configs.loki.limits_config, var.configs.loki.log_volume_enabled ? { "volume_enabled" : true } : {})
  ingress_annotations = merge(
    var.configs.loki.ingress.type == "alb" ? merge({
      "alb.ingress.kubernetes.io/target-type"      = "ip"
      "alb.ingress.kubernetes.io/scheme"           = var.configs.loki.ingress.public ? "internet-facing" : "internal"
      "alb.ingress.kubernetes.io/healthcheck-path" = "/api/health"
      "alb.ingress.kubernetes.io/listen-ports" = join(
        "",
        concat(
          ["["],
          [join(",", compact([
            "{\\\"HTTP\\\": 80}",
            var.configs.loki.ingress.tls.enabled ? "{\\\"HTTPS\\\": 443}" : null
          ]))],
          ["]"]
        )
      )
      }, var.configs.loki.ingress.tls.enabled ? {
      "alb.ingress.kubernetes.io/ssl-redirect" = "443"
      # "alb.ingress.kubernetes.io/certificate-arn" = var.configs.ingress.alb_certificate
    } : {}) : {},
    var.configs.loki.ingress.type == "nginx" ? merge({
      "nginx.ingress.kubernetes.io/backend-protocol"   = "HTTP"
      "nginx.ingress.kubernetes.io/proxy-buffer-size"  = "128k"
      "nginx.ingress.kubernetes.io/proxy-read-timeout" = "60"
      "nginx.ingress.kubernetes.io/proxy-send-timeout" = "60"
      }, var.configs.loki.ingress.tls.enabled ? {
      "nginx.ingress.kubernetes.io/ssl-redirect"       = "true"
      "nginx.ingress.kubernetes.io/force-ssl-redirect" = "true"
      # "cert-manager.io/cluster-issuer"                 = "letsencrypt-prod"
    } : {}) : {},
    var.configs.loki.ingress.annotations
  )

  ingress_tls = var.configs.loki.ingress.tls.enabled && var.configs.loki.ingress.type == "nginx" ? [{
    hosts       = var.configs.loki.ingress.hosts
    secret_name = join("-", [replace(var.configs.loki.ingress.hosts[0], ".", "-"), "tls"])
  }] : []

}
