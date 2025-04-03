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

  prometheus_datasource = var.prometheus_datasource.enabled ? {
    prometheus = {
      name        = "Prometheus"
      type        = "prometheus"
      url         = var.prometheus_datasource.url
      is_default  = true
      access_mode = "proxy"
    }
  } : {}

  cloudwatch_datasource = var.cloudwatch_datasource.enabled ? {
    cloudwatch = {
      name        = "CloudWatch"
      type        = "cloudwatch"
      access_mode = "proxy"
      json_data_encoded = jsonencode({
        authType      = "default"
        defaultRegion = var.cloudwatch_datasource.aws_region
        assumeRoleArn = module.grafana_cloudwatch_role[0].arn
      })
    }
  } : {}

  tempo_datasource = var.tempo_datasource.enabled ? {
    tempo = {
      name = "Tempo"
      type = "tempo"
      url  = var.tempo_datasource.url
    }
  } : {}

  loki_datasource = var.loki_datasource.enabled ? {
    loki = {
      name = "Loki"
      type = "loki"
      url  = var.loki_datasource.url
    }
  } : {}

  data_sources = merge(
    local.prometheus_datasource,
    local.cloudwatch_datasource,
    local.tempo_datasource,
    local.loki_datasource,
    var.additional_data_sources
  )
}
