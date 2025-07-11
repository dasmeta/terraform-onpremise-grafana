locals {
  eks_oidc_provider_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${replace(data.aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")}"

  cloudwatch_policies = [
    {
      actions = [
        "cloudwatch:DescribeAlarmsForMetric",
        "cloudwatch:DescribeAlarmHistory",
        "cloudwatch:DescribeAlarms",
        "cloudwatch:ListMetrics",
        "cloudwatch:GetMetricData",
        "cloudwatch:GetInsightRuleReport"
      ],
      resources = ["*"]
    },
    {
      actions   = ["ec2:DescribeTags", "ec2:DescribeInstances", "ec2:DescribeRegions"],
      resources = ["*"]
    },
    {
      actions   = ["tag:GetResources"],
      resources = ["*"]
    },
    {
      actions   = ["pi:GetResourceMetrics"],
      resources = ["*"]
    },
    {
      actions = [
        "logs:DescribeLogGroups",
        "logs:GetLogGroupFields",
        "logs:StartQuery",
        "logs:StopQuery",
        "logs:GetQueryResults",
        "logs:GetLogEvents"
      ],
      resources = ["*"]
    },
  ]

  default_datasource_configs = {
    prometheus = {
      type        = "prometheus"
      name        = "Prometheus"
      access_mode = "proxy"
      uid         = "prometheus"
      url         = "http://prometheus-operated.${var.namespace}.svc.cluster.local:9090"
      is_deafult  = false
    }
    cloudwatch = {
      type        = "cloudwatch"
      name        = "Cloudwatch"
      access_mode = "proxy"
      uid         = "cloudwatch"
      encoded_json = jsonencode({
        authType      = "default"
        defaultRegion = data.aws_region.current.name
      })
      is_default = false
    }
    loki = {
      type        = "loki"
      name        = "Loki"
      access_mode = "proxy"
      uid         = "loki"
      url         = "http://loki.${var.namespace}.svc.cluster.local:3100"
      is_default  = false
    }
    tempo = {
      type        = "tempo"
      name        = "Tempo"
      access_mode = "proxy"
      uid         = "tempo"
      url         = "http://tempo.${var.namespace}.svc.cluster.local:3100"
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
      "alb.ingress.kubernetes.io/ssl-redirect"    = "443"
      "alb.ingress.kubernetes.io/certificate-arn" = var.configs.ingress.alb_certificate
    } : {}) : {},
    var.configs.ingress.type == "nginx" ? merge({
      "nginx.ingress.kubernetes.io/backend-protocol"   = "HTTP"
      "nginx.ingress.kubernetes.io/proxy-buffer-size"  = "128k"
      "nginx.ingress.kubernetes.io/proxy-read-timeout" = "60"
      "nginx.ingress.kubernetes.io/proxy-send-timeout" = "60"
      }, var.configs.ingress.tls_enabled ? {
      "nginx.ingress.kubernetes.io/ssl-redirect"       = "true"
      "nginx.ingress.kubernetes.io/force-ssl-redirect" = "true"
      "cert-manager.io/cluster-issuer"                 = "letsencrypt-prod"
    } : {}) : {},
    var.configs.ingress.annotations
  )

  ingress_tls = var.configs.ingress.tls_enabled && var.configs.ingress.type == "nginx" ? [{
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
}
