locals {
  raw_extra_configs       = try(merge({}, var.extra_configs), {})
  raw_service             = try(merge({}, local.raw_extra_configs.service), {})
  raw_service_annotations = try(merge({}, local.raw_service.annotations), {})
  raw_extra_args          = try(tolist(local.raw_extra_configs.extraArgs), [])

  selector_owned_values = {
    fullnameOverride = var.fullname_override
    resources        = var.resources
    extraArgs = distinct(concat(
      local.raw_extra_args,
      ["--web.disable-exporter-metrics"],
    ))
    service = {
      enabled     = true
      port        = 9100
      servicePort = 9100
      targetPort  = 9100
      portName    = "metrics"
      annotations = merge(
        local.raw_service_annotations,
        { "prometheus.io/scrape" = "false" },
      )
    }
    prometheus = {
      monitor = {
        enabled = var.prometheus_monitor_enabled
        additionalLabels = {
          release = var.prometheus_release_name
        }
        selectorOverride = {
          "app.kubernetes.io/name"     = "prometheus-node-exporter"
          "app.kubernetes.io/instance" = var.release_name
        }
        metricRelabelings = [{
          sourceLabels = ["__name__"]
          regex        = "^go_.*"
          action       = "drop"
        }]
      }
    }
  }

  service_target = format(
    "%s.%s.svc.cluster.local:9100",
    var.fullname_override,
    var.namespace,
  )
}
