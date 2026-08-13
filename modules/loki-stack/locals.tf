locals {
  loki_release_name    = try(var.configs.loki.release_name, "loki")
  loki_deployment_mode = try(var.configs.loki.deploymentMode, "SingleBinary")
  loki_storage_type    = try(var.configs.loki.storage.type, "filesystem")

  loki_service_host = format("%s.%s.svc.cluster.local", local.loki_release_name, var.namespace)

  loki_query_url = (
    local.loki_deployment_mode == "SimpleScalable" ?
    format("http://%s-read.%s.svc.cluster.local:3100", local.loki_release_name, var.namespace) :
    local.loki_deployment_mode == "Distributed" ?
    format("http://%s-gateway.%s.svc.cluster.local:80", local.loki_release_name, var.namespace) :
    format("http://%s:3100", local.loki_service_host)
  )

  loki_push_url = (
    local.loki_deployment_mode == "SimpleScalable" ?
    format("http://%s-write.%s.svc.cluster.local:3100/loki/api/v1/push", local.loki_release_name, var.namespace) :
    local.loki_deployment_mode == "Distributed" ?
    format("http://%s-gateway.%s.svc.cluster.local:80/loki/api/v1/push", local.loki_release_name, var.namespace) :
    format("http://%s:3100/loki/api/v1/push", local.loki_service_host)
  )

  simple_scalable_component_defaults = {
    read    = 2
    write   = 2
    backend = 1
  }

  loki_read = local.loki_deployment_mode == "SimpleScalable" ? merge(
    { replicas = local.simple_scalable_component_defaults.read },
    try(var.configs.loki.read, {}),
  ) : try(var.configs.loki.read, { replicas = 0 })

  loki_write = local.loki_deployment_mode == "SimpleScalable" ? merge(
    { replicas = local.simple_scalable_component_defaults.write },
    try(var.configs.loki.write, {}),
  ) : try(var.configs.loki.write, { replicas = 0 })

  loki_backend = local.loki_deployment_mode == "SimpleScalable" ? merge(
    { replicas = local.simple_scalable_component_defaults.backend },
    try(var.configs.loki.backend, {}),
  ) : try(var.configs.loki.backend, { replicas = 0 })

  loki_schema_config = [
    for cfg in var.configs.loki.schemaConfig : merge(
      cfg,
      local.loki_deployment_mode == "SimpleScalable" && local.loki_storage_type != "filesystem" ? {
        object_store = local.loki_storage_type
      } : {}
    )
  ]

  loki_compactor_options = merge(
    var.configs.loki.compactor_options,
    local.loki_deployment_mode == "SimpleScalable" && local.loki_storage_type != "filesystem" ? {
      delete_request_store = local.loki_storage_type
    } : {}
  )

  promtail_clients = length(try(var.configs.promtail.clients, [])) > 0 ? var.configs.promtail.clients : [local.loki_push_url]

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
