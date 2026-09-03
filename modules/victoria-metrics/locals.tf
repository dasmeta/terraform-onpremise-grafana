locals {
  cluster_vminsert_service_name = trimsuffix(substr(
    "${var.release_name}-victoria-metrics-cluster-vminsert",
    0,
    63,
  ), "-")
  cluster_vmselect_service_name = trimsuffix(substr(
    "${var.release_name}-victoria-metrics-cluster-vmselect",
    0,
    63,
  ), "-")

  cluster_endpoint_contract = {
    vminsert = {
      enabled          = true
      fullnameOverride = local.cluster_vminsert_service_name
      ports = {
        name = "http"
      }
      extraArgs = {
        httpListenAddr = ":8480"
      }
      service = {
        enabled     = true
        servicePort = 8480
        targetPort  = "http"
        type        = "ClusterIP"
      }
      serviceMonitor = {
        enabled = false
      }
    }
    vmselect = {
      enabled          = true
      fullnameOverride = local.cluster_vmselect_service_name
      ports = {
        name = "http"
      }
      extraArgs = {
        httpListenAddr = ":8481"
      }
      service = {
        enabled     = true
        servicePort = 8481
        targetPort  = "http"
        type        = "ClusterIP"
      }
      serviceMonitor = {
        enabled = false
      }
    }
    vmstorage = {
      serviceMonitor = {
        enabled = false
      }
    }
    vmauth = {
      serviceMonitor = {
        enabled = false
      }
    }
  }

  agent_caller_scrape_configs = (
    var.agent_extra_scrape_configs == null
    ? []
    : var.agent_extra_scrape_configs
  )

  # Keep the native object distinct from the Operator-converted ServiceMonitor,
  # which uses the source monitor's name during the collector handoff.
  agent_kube_state_metrics_scrape_name = "${var.agent_kube_state_metrics_fullname}-victoria-metrics"

  agent_has_kube_state_metrics_scrape_config = try(anytrue([
    for scrape_config in local.agent_caller_scrape_configs :
    try(scrape_config.job_name, "") == "kube-state-metrics"
  ]), false)

  agent_protected_keys = [
    "replicaCount",
    "selectAllByDefault",
    "podScrapeSelector",
    "podScrapeNamespaceSelector",
    "serviceScrapeSelector",
    "serviceScrapeNamespaceSelector",
    "nodeScrapeSelector",
    "nodeScrapeNamespaceSelector",
    "remoteWrite",
    "inlineScrapeConfig",
    "resources",
    "extraArgs",
  ]

  agent_raw_extra_configs = (
    var.agent_extra_configs == null
    ? tomap({})
    : merge({}, var.agent_extra_configs)
  )

  agent_unprotected_extra_configs = {
    for key, value in local.agent_raw_extra_configs : key => value
    if !contains(local.agent_protected_keys, key)
  }

  agent_default_resources = {
    requests = {
      cpu    = "1"
      memory = "512Mi"
    }
    limits = {
      cpu    = "2"
      memory = "1Gi"
    }
  }

  agent_raw_resource_requests = try(
    local.agent_raw_extra_configs.resources.requests,
    null,
  )
  agent_raw_resource_limits = try(
    local.agent_raw_extra_configs.resources.limits,
    null,
  )
  agent_raw_extra_args = try(local.agent_raw_extra_configs.extraArgs, null)

  agent_resources = {
    requests = merge(
      local.agent_default_resources.requests,
      local.agent_raw_resource_requests == null
      ? tomap({})
      : merge({}, local.agent_raw_resource_requests),
    )
    limits = merge(
      local.agent_default_resources.limits,
      local.agent_raw_resource_limits == null
      ? tomap({})
      : merge({}, local.agent_raw_resource_limits),
    )
  }

  agent_extra_args = merge(
    { "remoteWrite.queues" = "16" },
    local.agent_raw_extra_args == null
    ? tomap({})
    : merge({}, local.agent_raw_extra_args),
  )

  agent_object = {
    apiVersion = "operator.victoriametrics.com/v1beta1"
    kind       = "VMAgent"
    metadata = {
      name      = var.agent_name
      namespace = var.namespace
    }
    spec = merge(
      local.agent_unprotected_extra_configs,
      {
        resources = local.agent_resources
        extraArgs = local.agent_extra_args
      },
      {
        replicaCount       = var.agent_replica_count
        selectAllByDefault = true
        remoteWrite        = [{ url = local.agent_remote_write_url }]
        inlineScrapeConfig = yamlencode(local.agent_caller_scrape_configs)
      }
    )
  }

  agent_kube_state_metrics_object = {
    apiVersion = "operator.victoriametrics.com/v1beta1"
    kind       = "VMServiceScrape"
    metadata = {
      name      = local.agent_kube_state_metrics_scrape_name
      namespace = var.agent_kube_state_metrics_namespace
    }
    spec = {
      namespaceSelector = {
        matchNames = [var.agent_kube_state_metrics_namespace]
      }
      selector = {
        matchLabels = {
          "app.kubernetes.io/name"     = "kube-state-metrics"
          "app.kubernetes.io/instance" = var.agent_kube_state_metrics_release_name
        }
      }
      endpoints = [{
        port            = "http"
        honorLabels     = true
        max_scrape_size = "32MiB"
      }]
    }
  }

  agent_node_exporter_scrape_name = "${var.agent_node_exporter_fullname}-victoria-metrics"

  agent_node_exporter_object = {
    apiVersion = "operator.victoriametrics.com/v1beta1"
    kind       = "VMServiceScrape"
    metadata = {
      name      = local.agent_node_exporter_scrape_name
      namespace = var.agent_node_exporter_namespace
    }
    spec = {
      namespaceSelector = {
        matchNames = [var.agent_node_exporter_namespace]
      }
      selector = {
        matchLabels = {
          "app.kubernetes.io/name"     = "prometheus-node-exporter"
          "app.kubernetes.io/instance" = var.agent_node_exporter_release_name
        }
      }
      endpoints = [{
        port        = "metrics"
        path        = "/metrics"
        honorLabels = true
        metricRelabelConfigs = [{
          source_labels = ["__name__"]
          regex         = "^go_.*"
          action        = "drop"
        }]
      }]
    }
  }

  agent_tempo_object = {
    apiVersion = "operator.victoriametrics.com/v1beta1"
    kind       = "VMServiceScrape"
    metadata = {
      name      = "${var.agent_tempo_release_name}-victoria-metrics"
      namespace = var.agent_tempo_namespace
    }
    spec = {
      namespaceSelector = {
        matchNames = [var.agent_tempo_namespace]
      }
      selector = {
        matchLabels = {
          "app.kubernetes.io/name"     = "tempo"
          "app.kubernetes.io/instance" = var.agent_tempo_release_name
        }
      }
      endpoints = concat(
        [{ port = "tempo-prom-metrics", path = "/metrics" }],
        var.agent_tempo_query_enabled ? [{ port = "jaeger-metrics", path = "/metrics" }] : [],
      )
    }
  }

  agent_loki_object = {
    apiVersion = "operator.victoriametrics.com/v1beta1"
    kind       = "VMServiceScrape"
    metadata = {
      name      = "${var.agent_loki_release_name}-victoria-metrics"
      namespace = var.agent_loki_namespace
    }
    spec = {
      namespaceSelector = {
        matchNames = [var.agent_loki_namespace]
      }
      selector = {
        matchLabels = {
          "app.kubernetes.io/name"     = "loki"
          "app.kubernetes.io/instance" = var.agent_loki_release_name
        }
      }
      endpoints = [{
        port     = "http-metrics"
        path     = "/metrics"
        interval = "15s"
      }]
    }
  }

  agent_node_scrape_endpoints = {
    kubelet = {
      enabled = var.agent_kubelet_scrape_enabled
      path    = "/metrics"
    }
    cadvisor = {
      enabled = var.agent_cadvisor_scrape_enabled
      path    = "/metrics/cadvisor"
    }
    resource = {
      enabled = var.agent_resource_scrape_enabled
      path    = "/metrics/resource"
    }
  }

  agent_node_scrape_objects = [
    for endpoint_name, endpoint in local.agent_node_scrape_endpoints : {
      apiVersion = "operator.victoriametrics.com/v1beta1"
      kind       = "VMNodeScrape"
      metadata = {
        name      = "${var.agent_name}-${endpoint_name}"
        namespace = var.namespace
      }
      spec = {
        scheme          = "https"
        path            = endpoint.path
        interval        = "30s"
        scrapeTimeout   = "5s"
        honorLabels     = true
        honorTimestamps = false
        bearerTokenFile = "/var/run/secrets/kubernetes.io/serviceaccount/token"
        tlsConfig = {
          caFile             = "/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"
          insecureSkipVerify = true
        }
        relabelConfigs = [
          {
            action = "labelmap"
            regex  = "__meta_kubernetes_node_label_(.+)"
          },
          {
            sourceLabels = ["__meta_kubernetes_node_name"]
            targetLabel  = "node"
          },
          {
            sourceLabels = ["__meta_kubernetes_node_name"]
            targetLabel  = "instance"
          },
          {
            sourceLabels = ["__metrics_path__"]
            targetLabel  = "metrics_path"
          },
          {
            targetLabel = "job"
            replacement = "kubelet"
          },
        ]
        metricRelabelConfigs = [{
          source_labels = ["__name__"]
          regex         = format("^(%s)$", join("|", var.agent_kubelet_metrics))
          action        = "keep"
        }]
      }
    } if var.agent_enabled && endpoint.enabled
  ]

  operator_objects = concat(
    (
      var.agent_enabled &&
      var.agent_kube_state_metrics_enabled &&
      !local.agent_has_kube_state_metrics_scrape_config
    ) ? [local.agent_kube_state_metrics_object] : [],
    (
      var.agent_enabled &&
      var.agent_node_exporter_enabled
    ) ? [local.agent_node_exporter_object] : [],
    (
      var.agent_enabled &&
      var.agent_tempo_enabled
    ) ? [local.agent_tempo_object] : [],
    (
      var.agent_enabled &&
      var.agent_loki_enabled
    ) ? [local.agent_loki_object] : [],
    local.agent_node_scrape_objects,
    var.agent_enabled ? [local.agent_object] : [],
  )

  operator_raw_extra_configs = (
    var.operator_extra_configs == null
    ? tomap({})
    : merge({}, var.operator_extra_configs)
  )

  operator_raw_extra_args = try(local.operator_raw_extra_configs.extraArgs, null)

  operator_extra_args = merge(
    local.operator_raw_extra_args == null
    ? tomap({})
    : merge({}, local.operator_raw_extra_args),
    { "controller.disableReconcileFor" = [] },
  )

  operator_raw_env = try(local.operator_raw_extra_configs.env, null)

  operator_env = [
    for env_var in(local.operator_raw_env == null ? [] : local.operator_raw_env) : env_var
    if(
      try(env_var.name, "") != "WATCH_NAMESPACE" &&
      !can(regex(
        "^VM_ENABLEDPROMETHEUSCONVERTER",
        try(env_var.name, ""),
      ))
    )
  ]

  operator_selector_owned_values = {
    operator = {
      disable_prometheus_converter = !var.prometheus_converter_enabled
      enable_converter_ownership   = var.prometheus_converter_enabled
    }
    watchNamespaces = []
    extraArgs       = local.operator_extra_args
    env             = local.operator_env
    envFrom         = []
    rbac = {
      create = true
    }
    crds = {
      enabled = true
      plain   = true
      cleanup = {
        enabled = false
      }
      upgrade = {
        enabled = true
      }
    }
    serviceMonitor = {
      enabled = false
      vm      = true
    }
    extraObjects = []
  }

  agent_remote_write_url = format(
    "http://%s.%s.svc.cluster.local:8480/insert/0/prometheus/api/v1/write",
    local.cluster_vminsert_service_name,
    var.namespace
  )
}
