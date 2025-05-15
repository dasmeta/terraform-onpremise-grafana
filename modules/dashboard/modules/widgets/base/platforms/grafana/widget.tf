locals {
  field_config_defaults = {
    "color" : {
      "mode" : try(var.color_mode, "palette-classic")
    },
    decimals : var.decimals,
    "custom" : {
      "axisLabel" : "",
      "axisPlacement" : "auto",
      "barAlignment" : 0,
      "drawStyle" : "line",
      "fillOpacity" : var.fillOpacity,
      "gradientMode" : "none",
      "hideFrom" : {
        "legend" : false,
        "tooltip" : false,
        "viz" : false
      },
      "lineInterpolation" : "linear",
      "lineWidth" : 1,
      "pointSize" : 5,
      "scaleDistribution" : {
        "type" : "linear"
      },
      "showPoints" : "auto",
      "spanNulls" : false,
      "stacking" : {
        "group" : "A",
        "mode" : "none"
      },
      "thresholdsStyle" : {
        "mode" : "off"
      }
    },
    mappings = []
    thresholds = try(var.thresholds, {
      mode = "absolute",
      steps = [
        { color = "green", value = null },
        { color = "red", value = 80 }
      ]
    })
    unit = var.unit
  }

  field_config_overrides = [
    for metric in local.metrics_with_defaults : {
      matcher = {
        id      = "byName"
        options = metric.label
      }
      properties = [
        {
          id = "color"
          value = {
            mode       = "fixed"
            fixedColor = format("#%s", metric.color)
          }
        }
      ]
    } if metric.color != null
  ]


  common_fields    = ["MetricNamespace", "MetricName"]
  attribute_fields = ["accountId", "period", "stat", "label", "visible", "color", "yAxis"]
  custom_fields    = ["anomaly_detection", "anomaly_deviation"]
  metrics_local    = var.metrics == null ? [] : var.metrics

  # merge metrics with defaults
  metrics_with_defaults = [for metric in local.metrics_local : merge(var.defaults, metric, {
    color = lookup(metric, "color", null)
  })]

  type_map = {
    timeSeries = "timeseries"
    gauge      = "gauge"
    histogram  = "histogram"
    stat       = "stat"
  }

  # create query and metric based targets
  query_targets = var.query != null ? [
    {
      expression    = var.query,
      logGroupNames = var.sources,
      queryMode     = "Logs",
      legendFormat  = ""
      # region        = var.region
    }
  ] : []
  metric_targets = [for row in local.metrics_with_defaults : {
    expr         = row.expression
    id           = ""
    legendFormat = row.label,
    editorMode   = "code",

    }
    #   : {
    #   expression       = ""
    #   id               = ""
    #   matchExact       = true
    #   metricEditorMode = 0
    #   metricName       = row.metricName
    #   metricQueryType  = 0
    #   namespace        = row.metricNamespace
    #   queryLanguage    = try(row.queryLanguage, "")
    #   period           = ""
    #   queryMode        = "Metrics"
    #   region           = try(row.region, "")
    #   sqlExpression = ""
    #   editorMode   = "code"
    #   statistic     = "Average"
    #   dimensions    = { for key, item in row : key => item if !contains(concat(local.common_fields, local.attribute_fields, local.custom_fields), key) }
    # }]
  ]

  cloudwatch_targets = [for row in var.cloudwatch_targets : {
    datasource = {
      type = try(var.data_source.type, "")
      uid  = try(var.data_source.uid, "")
    }
    queryMode        = row.query_mode
    region           = row.region
    namespace        = row.namespace
    metricName       = row.metric_name
    dimensions       = row.dimensions
    statistic        = row.statistic
    period           = row.period
    matchExact       = true
    expression       = ""
    id               = ""
    metricEditorMode = 0
    metricQueryType  = 0
    refId            = row.refId
  }]

  data = {
    datasource  = var.data_source
    description = var.description
    fieldConfig = {
      defaults  = local.field_config_defaults
      overrides = local.field_config_overrides
    }
    gridPos = {
      h = var.coordinates.height
      w = var.coordinates.width
      x = var.coordinates.x
      y = var.coordinates.y
    }
    title = var.name
    type  = try(local.type_map[var.view], local.type_map.timeSeries)
    options = {
      legend = {
        calcs       = lookup(var.options.legend, "calcs", [])
        displayMode = lookup(var.options.legend, "displayMode", "list")
        placement   = lookup(var.options.legend, "placement", "bottom")
        showLegend  = lookup(var.options.legend, "show_legend", true)
      }
      tooltip = {
        mode = lookup(var.options.tooltip, "mode", "single")
        sort = lookup(var.options.tooltip, "sort", "none")
      }
    }
    targets = concat(local.query_targets, local.metric_targets, local.cloudwatch_targets)
  }
}
