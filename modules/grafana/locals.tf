locals {

  default_datasource_configs = {
    prometheus = {
      type        = "prometheus"
      name        = "Prometheus"
      access_mode = "proxy"
      uid         = "prometheus"
      url         = "http://prometheus-operated.${var.namespace}.svc.cluster.local:9090"
      is_default  = true
    }
    loki = {
      type        = "loki"
      name        = "Loki"
      access_mode = "proxy"
      uid         = "loki"
      url         = "http://loki.${var.namespace}.svc.cluster.local:3100"
      is_default  = false
      encoded_json = jsonencode(merge(
        var.configs.trace_log_mapping.enabled ?
        {
          derivedFields = [
            {
              name          = "traceID"
              matcherRegex  = var.configs.trace_log_mapping.trace_pattern
              datasourceUid = "tempo"
              url           = "$${__value.raw}"
            }
          ]
        } : {}
      ))
    }
    tempo = {
      type        = "tempo"
      name        = "Tempo"
      access_mode = "proxy"
      uid         = "tempo"
      url         = "http://tempo.${var.namespace}.svc.cluster.local:3200"
      is_default  = false

      encoded_json = jsonencode({
        httpMethod = "GET"
        tracesToLogsV2 = {
          datasourceUid = "loki"
        }
        tracesToMetrics = {
          datasourceUid = "prometheus"
        }
      })
    }
  }

  merged_datasources = {
    for ds in var.datasources : ds.name => merge(
      lookup(local.default_datasource_configs, ds.type, {}),
      ds
    )
  }

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
            var.configs.ingress.tls.enabled ? "{\\\"HTTPS\\\": 443}" : null
          ]))],
          ["]"]
        )
      )

      }, var.configs.ingress.tls.enabled ? {
      "alb.ingress.kubernetes.io/ssl-redirect" = "443"
    } : {}) : {},
    var.configs.ingress.type == "nginx" ? merge({
      "nginx.ingress.kubernetes.io/backend-protocol"   = "HTTP"
      "nginx.ingress.kubernetes.io/proxy-buffer-size"  = "128k"
      "nginx.ingress.kubernetes.io/proxy-read-timeout" = "60"
      "nginx.ingress.kubernetes.io/proxy-send-timeout" = "60"
      }, var.configs.ingress.tls.enabled ? {
      "nginx.ingress.kubernetes.io/ssl-redirect"       = "true"
      "nginx.ingress.kubernetes.io/force-ssl-redirect" = "true"
      # "cert-manager.io/cluster-issuer"                 = var.configs.ingress.tls.cert_provider
    } : {}) : {},
    var.configs.ingress.annotations
  )

  ingress_tls = var.configs.ingress.tls.enabled && var.configs.ingress.type == "nginx" ? [{
    hosts       = var.configs.ingress.hosts
    secret_name = join("-", [replace(var.configs.ingress.hosts[0], ".", "-"), "tls"])
  }] : []

  database = {
    host          = coalesce(var.configs.database.host, "${var.mysql_release_name}.${var.namespace}")
    username      = coalesce(var.configs.database.user, "grafana")
    password      = coalesce(var.configs.database.password, var.grafana_admin_password)
    root_password = coalesce(var.configs.database.root_password, var.grafana_admin_password)
    name          = coalesce(var.configs.database.name, "grafana"),
    type          = var.configs.database.create ? "mysql" : coalesce(var.configs.database.type, "mysql"),
  }

  grafana_root_url = "https://${var.configs.ingress.hosts[0]}"
}
