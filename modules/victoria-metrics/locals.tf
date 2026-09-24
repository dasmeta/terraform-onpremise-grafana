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

  agent_kubernetes_component_definitions = {
    core_dns = {
      enabled                  = var.agent_kubernetes_component_scrapes.core_dns
      slug                     = "coredns"
      pod_selector             = tomap({ "k8s-app" = "kube-dns" })
      job_label                = "coredns"
      port                     = 9153
      scheme                   = "http"
      tls_enabled              = false
      tls_ca_file              = null
      tls_server_name          = null
      tls_insecure_skip_verify = false
      drop_go_metrics          = true
    }
    kube_proxy = {
      enabled                  = var.agent_kubernetes_component_scrapes.kube_proxy
      slug                     = "kube-proxy"
      pod_selector             = tomap({ "k8s-app" = "kube-proxy" })
      job_label                = "kube-proxy"
      port                     = 10249
      scheme                   = "http"
      tls_enabled              = false
      tls_ca_file              = null
      tls_server_name          = null
      tls_insecure_skip_verify = false
      drop_go_metrics          = true
    }
    controller_manager = {
      enabled                  = var.agent_kubernetes_component_scrapes.controller_manager
      slug                     = "kube-controller-manager"
      pod_selector             = tomap({ component = "kube-controller-manager" })
      job_label                = "kube-controller-manager"
      port                     = 10257
      scheme                   = "https"
      tls_enabled              = true
      tls_ca_file              = try(var.agent_kubernetes_component_scrapes.controller_manager_tls.ca_file, null)
      tls_server_name          = try(var.agent_kubernetes_component_scrapes.controller_manager_tls.server_name, null)
      tls_insecure_skip_verify = try(var.agent_kubernetes_component_scrapes.controller_manager_tls.insecure_skip_verify, false)
      drop_go_metrics          = false
    }
    scheduler = {
      enabled                  = var.agent_kubernetes_component_scrapes.scheduler
      slug                     = "kube-scheduler"
      pod_selector             = tomap({ component = "kube-scheduler" })
      job_label                = "kube-scheduler"
      port                     = 10259
      scheme                   = "https"
      tls_enabled              = true
      tls_ca_file              = try(var.agent_kubernetes_component_scrapes.scheduler_tls.ca_file, null)
      tls_server_name          = try(var.agent_kubernetes_component_scrapes.scheduler_tls.server_name, null)
      tls_insecure_skip_verify = try(var.agent_kubernetes_component_scrapes.scheduler_tls.insecure_skip_verify, false)
      drop_go_metrics          = false
    }
    etcd = {
      enabled                  = var.agent_kubernetes_component_scrapes.etcd
      slug                     = "kube-etcd"
      pod_selector             = tomap({ component = "etcd" })
      job_label                = "kube-etcd"
      port                     = 2381
      scheme                   = "http"
      tls_enabled              = false
      tls_ca_file              = null
      tls_server_name          = null
      tls_insecure_skip_verify = false
      drop_go_metrics          = false
    }
  }

  agent_kubernetes_component_raw_service_names = {
    for component_name, component in local.agent_kubernetes_component_definitions :
    component_name => "${replace(var.agent_name, ".", "-")}-${component.slug}"
  }

  agent_kubernetes_component_service_names = {
    for component_name, raw_name in local.agent_kubernetes_component_raw_service_names :
    component_name => (
      length(raw_name) <= 63
      ? raw_name
      : "${trim(substr(raw_name, 0, 54), "-")}-${substr(sha1(raw_name), 0, 8)}"
    )
  }

  agent_kubernetes_component_raw_scrape_names = {
    for component_name, service_name in local.agent_kubernetes_component_service_names :
    component_name => "${service_name}-victoria-metrics"
  }

  agent_kubernetes_component_scrape_names = {
    for component_name, raw_name in local.agent_kubernetes_component_raw_scrape_names :
    component_name => (
      length(raw_name) <= 63
      ? raw_name
      : "${trim(substr(raw_name, 0, 54), "-")}-${substr(sha1(raw_name), 0, 8)}"
    )
  }

  agent_kubernetes_component_service_objects = [
    for component_name, component in local.agent_kubernetes_component_definitions : {
      apiVersion = "v1"
      kind       = "Service"
      metadata = {
        name      = local.agent_kubernetes_component_service_names[component_name]
        namespace = var.agent_kubernetes_component_scrapes.namespace
        labels = {
          "monitoring.dasmeta.com/component" = component_name
          jobLabel                           = component.job_label
        }
      }
      spec = {
        clusterIP = "None"
        type      = "ClusterIP"
        selector  = component.pod_selector
        ports = [{
          name       = "http-metrics"
          port       = component.port
          protocol   = "TCP"
          targetPort = component.port
        }]
      }
    } if var.agent_enabled && var.agent_standalone && component.enabled
  ]

  agent_kubernetes_component_scrape_objects = [
    for component_name, component in local.agent_kubernetes_component_definitions : {
      apiVersion = "operator.victoriametrics.com/v1beta1"
      kind       = "VMServiceScrape"
      metadata = {
        name      = local.agent_kubernetes_component_scrape_names[component_name]
        namespace = var.namespace
      }
      spec = {
        jobLabel = "jobLabel"
        namespaceSelector = {
          matchNames = [var.agent_kubernetes_component_scrapes.namespace]
        }
        selector = {
          matchLabels = {
            "monitoring.dasmeta.com/component" = component_name
          }
        }
        endpoints = [merge(
          {
            port          = "http-metrics"
            path          = "/metrics"
            scheme        = component.scheme
            interval      = "30s"
            scrapeTimeout = "10s"
          },
          component.tls_enabled ? {
            bearerTokenFile = "/var/run/secrets/kubernetes.io/serviceaccount/token"
          } : {},
          component.tls_enabled ? {
            tlsConfig = merge(
              {
                insecureSkipVerify = component.tls_insecure_skip_verify
              },
              component.tls_ca_file == null ? {} : {
                caFile = component.tls_ca_file
              },
              component.tls_server_name == null ? {} : {
                serverName = component.tls_server_name
              },
            )
          } : {},
          component.drop_go_metrics ? {
            metricRelabelConfigs = [{
              source_labels = ["__name__"]
              regex         = "^go_.*"
              action        = "drop"
            }]
          } : {},
        )]
      }
    } if var.agent_enabled && var.agent_standalone && component.enabled
  ]

  agent_kubernetes_api_server_raw_scrape_name = "${replace(var.agent_name, ".", "-")}-kube-apiserver-victoria-metrics"
  agent_kubernetes_api_server_scrape_name = (
    length(local.agent_kubernetes_api_server_raw_scrape_name) <= 63
    ? local.agent_kubernetes_api_server_raw_scrape_name
    : "${trim(substr(local.agent_kubernetes_api_server_raw_scrape_name, 0, 54), "-")}-${substr(sha1(local.agent_kubernetes_api_server_raw_scrape_name), 0, 8)}"
  )

  agent_kubernetes_api_server_object = {
    apiVersion = "operator.victoriametrics.com/v1beta1"
    kind       = "VMServiceScrape"
    metadata = {
      name      = local.agent_kubernetes_api_server_scrape_name
      namespace = var.namespace
    }
    spec = {
      jobLabel = "component"
      namespaceSelector = {
        matchNames = [var.agent_kubernetes_component_scrapes.api_server_namespace]
      }
      selector = {
        matchLabels = {
          component = "apiserver"
          provider  = "kubernetes"
        }
      }
      endpoints = [{
        port            = "https"
        path            = "/metrics"
        scheme          = "https"
        interval        = "30s"
        scrapeTimeout   = "10s"
        bearerTokenFile = "/var/run/secrets/kubernetes.io/serviceaccount/token"
        tlsConfig = {
          caFile             = "/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"
          serverName         = "kubernetes"
          insecureSkipVerify = false
        }
        metricRelabelConfigs = [{
          source_labels = ["__name__", "le"]
          regex         = "(etcd_request|apiserver_request_slo|apiserver_request_sli|apiserver_request)_duration_seconds_bucket;(0\\.15|0\\.2|0\\.3|0\\.35|0\\.4|0\\.45|0\\.6|0\\.7|0\\.8|0\\.9|1\\.25|1\\.5|1\\.75|2|3|3\\.5|4|4\\.5|6|7|8|9|15|20|40|45|50)(\\.0)?"
          action        = "drop"
        }]
      }]
    }
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
        metricRelabelConfigs = [{
          source_labels = ["__name__"]
          regex         = "^go_.*"
          action        = "drop"
        }]
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

  agent_node_metric_endpoint_names = {
    "container_cpu_.*"                 = ["cadvisor", "resource"]
    "container_memory_.*"              = ["cadvisor", "resource"]
    "container_network_.*"             = ["cadvisor"]
    "container_fs_.*"                  = ["cadvisor"]
    "pod_cpu_usage_seconds_total"      = ["resource"]
    "pod_memory_working_set_bytes"     = ["resource"]
    "kubelet_volume_stats.*"           = ["kubelet"]
    "volume_operation_total_seconds.*" = ["kubelet"]

    # These families come from kube-state-metrics or kube-scheduler, not from
    # any kubelet node endpoint. Keep them classified so legacy caller values
    # are discarded instead of being treated as unknown custom patterns.
    "kube_pod_container_status_.*"   = []
    "kube_pod_container_resource_.*" = []
    "kube_pod_resource_limit"        = []
    "kube_pod_resource_request"      = []
    "pod_memory_usage_bytes"         = []
  }

  agent_node_scrape_endpoint_definitions = {
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

  agent_node_scrape_endpoints = {
    for endpoint_name, endpoint in local.agent_node_scrape_endpoint_definitions :
    endpoint_name => merge(endpoint, {
      metrics = [
        for pattern in var.agent_kubelet_metrics : pattern
        if try(contains(local.agent_node_metric_endpoint_names[pattern], endpoint_name), true)
      ]
    })
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
          regex         = format("^(%s)$", join("|", endpoint.metrics))
          action        = "keep"
        }]
      }
    } if var.agent_enabled && endpoint.enabled
  ]

  operator_objects = concat(
    local.agent_kubernetes_component_service_objects,
    local.agent_kubernetes_component_scrape_objects,
    (
      var.agent_enabled &&
      var.agent_standalone &&
      var.agent_kubernetes_component_scrapes.api_server
    ) ? [local.agent_kubernetes_api_server_object] : [],
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
    # Deliberately differs from the chart default: plain CRDs bootstrap the API
    # before the dependent custom-resource release, while the upgrade hook
    # updates CRDs that Helm does not upgrade from its crds/ directory.
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
