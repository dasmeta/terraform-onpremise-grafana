locals {
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
      jsonData = {
        authType      = "default"
        defaultRegion = "us-east-2"
        assumeRoleArn = null
      }
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

      json_data_encoded = jsonencode({
        httpMethod = "GET"
        traceToLogs = {
          datasourceUid      = "loki"
          spanStartTimeShift = "1h"
          spanEndTimeShift   = "1h"
          filterByTraceID    = true
          filterBySpanID     = false
          tags = [
            {
              key   = "job"
              value = ".*"
            }
          ]
        }
      })
    }
  }

  _merged_base = {
    for ds in var.datasources : ds.name => merge(
      lookup(local.default_datasource_configs, ds.type, {}),
      ds
    )
  }

  merged_datasources = {
    for name, ds in local._merged_base : name => (
      merge(
        ds,
        {
          jsonData = merge(
            lookup(ds, "jsonData", {}),
            ds.type == "cloudwatch" && try(ds.jsonData.assumeRoleArn, "") == ""
            ? {
              assumeRoleArn = try(module.grafana_cloudwatch_role[0].arn, "")
            }
            : {}
          )
        }
      )
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
}
