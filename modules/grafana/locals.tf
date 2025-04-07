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
      url         = "http://prometheus-operated.${var.namespace}.svc.cluster.local:9090"
      is_deafult  = false
    }
    cloudwatch = {
      type        = "cloudwatch"
      name        = "Cloudwatch"
      access_mode = "proxy"
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
      url         = "http://loki.${var.namespace}.svc.cluster.local:3100"
      is_default  = false
    }
    tempo = {
      type        = "tempo"
      name        = "Tempo"
      access_mode = "proxy"
      url         = "http://tempo.${var.namespace}.svc.cluster.local:3100"
      is_default  = false
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
}
