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
      url         = "http://prometheus-operated.monitoring.svc.cluster.local:9090"
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
      url         = "http://loki.monitoring.svc.cluster.local:3100"
      is_default  = false
    }
    tempo = {
      type        = "tempo"
      name        = "Tempo"
      access_mode = "proxy"
      url         = "http://tempo.monitoring.svc.cluster.local:3100"
      is_default  = false
    }
  }

  _merged_base = {
    for ds in var.datasources : ds.type => merge(
      lookup(local.default_datasource_configs, ds.type, {}),
      ds
    )
  }

  merged_datasources = {
    for k, v in local._merged_base : k => merge(
      v,
      {
        jsonData = merge(
          lookup(v, "jsonData", {}),
          k == "cloudwatch" ? {
            assumeRoleArn = try(module.grafana_cloudwatch_role[0].arn, "")
          } : {}
        )
      }
    )
  }
}
