mock_provider "helm" {}

run "victoria_mode_generates_victoria_metrics_agent_and_native_ksm" {
  command = plan

  module {
    source = "../../modules/victoria-metrics"
  }

  variables {
    operator_enabled = true
    namespace        = "monitoring"
    release_name     = "victoria-metrics"
    configs          = {}
    agent_enabled    = true
  }

  assert {
    condition = alltrue([
      one([
        for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : object
        if try(object.kind, "") == "VMAgent"
      ]).metadata.name == "victoria-metrics-agent",
      one([
        for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : object
        if try(object.kind, "") == "VMAgent"
      ]).metadata.namespace == "monitoring",
      one([
        for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : object
        if try(object.kind, "") == "VMAgent"
      ]).spec.replicaCount == 1,
      one([
        for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : object
        if try(object.kind, "") == "VMAgent"
      ]).spec.selectAllByDefault == true,
      one([
        for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : object
        if try(object.kind, "") == "VMAgent"
      ]).spec.remoteWrite[0].url == "http://victoria-metrics-victoria-metrics-cluster-vminsert.monitoring.svc.cluster.local:8480/insert/0/prometheus/api/v1/write",
      length(yamldecode(one([
        for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : object
        if try(object.kind, "") == "VMAgent"
      ]).spec.inlineScrapeConfig)) == 0,
      one([
        for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : object
        if try(object.kind, "") == "VMAgent"
      ]).spec.resources.requests.cpu == "1",
      one([
        for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : object
        if try(object.kind, "") == "VMAgent"
      ]).spec.resources.requests.memory == "512Mi",
      one([
        for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : object
        if try(object.kind, "") == "VMAgent"
      ]).spec.resources.limits.cpu == "2",
      one([
        for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : object
        if try(object.kind, "") == "VMAgent"
      ]).spec.resources.limits.memory == "1Gi",
      one([
        for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : object
        if try(object.kind, "") == "VMAgent"
      ]).spec.extraArgs["remoteWrite.queues"] == "16",
    ])
    error_message = "Victoria mode must render the exact protected VMAgent defaults."
  }

  assert {
    condition = alltrue([
      length([
        for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : object
        if try(object.kind, "") == "VMServiceScrape"
      ]) == 1,
      one([
        for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : object
        if try(object.kind, "") == "VMServiceScrape"
      ]).metadata.name == "prometheus-kube-state-metrics-victoria-metrics",
      one([
        for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : object
        if try(object.kind, "") == "VMServiceScrape"
      ]).metadata.namespace == "monitoring",
      one([
        for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : object
        if try(object.kind, "") == "VMServiceScrape"
      ]).spec.namespaceSelector.matchNames == ["monitoring"],
      one([
        for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : object
        if try(object.kind, "") == "VMServiceScrape"
      ]).spec.selector.matchLabels["app.kubernetes.io/name"] == "kube-state-metrics",
      one([
        for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : object
        if try(object.kind, "") == "VMServiceScrape"
      ]).spec.selector.matchLabels["app.kubernetes.io/instance"] == "kube-state-metrics",
      one([
        for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : object
        if try(object.kind, "") == "VMServiceScrape"
      ]).spec.endpoints[0].port == "http",
      one([
        for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : object
        if try(object.kind, "") == "VMServiceScrape"
      ]).spec.endpoints[0].honorLabels == true,
      one([
        for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : object
        if try(object.kind, "") == "VMServiceScrape"
      ]).spec.endpoints[0].max_scrape_size == "32MiB",
      length(try(one([
        for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : object
        if try(object.kind, "") == "VMServiceScrape"
      ]).spec.endpoints[0].metricRelabelConfigs, [])) == 1,
      try(one([
        for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : object
        if try(object.kind, "") == "VMServiceScrape"
      ]).spec.endpoints[0].metricRelabelConfigs[0].source_labels, []) == ["__name__"],
      try(one([
        for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : object
        if try(object.kind, "") == "VMServiceScrape"
      ]).spec.endpoints[0].metricRelabelConfigs[0].regex, null) == "^go_.*",
      try(one([
        for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : object
        if try(object.kind, "") == "VMServiceScrape"
      ]).spec.endpoints[0].metricRelabelConfigs[0].action, null) == "drop",
      length([
        for scrape_config in yamldecode(one([
          for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : object
          if try(object.kind, "") == "VMAgent"
        ]).spec.inlineScrapeConfig) : scrape_config
        if try(scrape_config.job_name, "") == "kube-state-metrics"
      ]) == 0,
    ])
    error_message = "Victoria mode must render exactly one native KSM object with go runtime filtering and no static KSM job."
  }

  assert {
    condition = alltrue([
      length([
        for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : object
        if try(object.kind, "") == "VMNodeScrape"
      ]) == 2,
      toset([
        for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : object.metadata.name
        if try(object.kind, "") == "VMNodeScrape"
        ]) == toset([
        "victoria-metrics-agent-kubelet",
        "victoria-metrics-agent-cadvisor",
      ]),
      toset([
        for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : object.spec.path
        if try(object.kind, "") == "VMNodeScrape"
      ]) == toset(["/metrics", "/metrics/cadvisor"]),
      alltrue([
        for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : alltrue([
          object.apiVersion == "operator.victoriametrics.com/v1beta1",
          object.metadata.namespace == "monitoring",
          object.spec.scheme == "https",
          object.spec.bearerTokenFile == "/var/run/secrets/kubernetes.io/serviceaccount/token",
          !contains(keys(object.spec.tlsConfig), "caFile"),
          object.spec.tlsConfig.insecureSkipVerify == true,
          object.spec.interval == "30s",
          object.spec.scrapeTimeout == "5s",
          object.spec.relabelConfigs[0].action == "labelmap",
          object.spec.relabelConfigs[0].regex == "__meta_kubernetes_node_label_(.+)",
          object.spec.relabelConfigs[1].sourceLabels == ["__meta_kubernetes_node_name"],
          object.spec.relabelConfigs[1].targetLabel == "node",
          object.spec.relabelConfigs[2].sourceLabels == ["__meta_kubernetes_node_name"],
          object.spec.relabelConfigs[2].targetLabel == "instance",
          object.spec.relabelConfigs[3].sourceLabels == ["__metrics_path__"],
          object.spec.relabelConfigs[3].targetLabel == "metrics_path",
          object.spec.relabelConfigs[4].targetLabel == "job",
          object.spec.relabelConfigs[4].replacement == "kubelet",
          object.spec.metricRelabelConfigs[0].source_labels == ["__name__"],
          object.spec.metricRelabelConfigs[0].action == "keep",
        ])
        if try(object.kind, "") == "VMNodeScrape"
      ]),
      one([
        for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : object
        if try(object.kind, "") == "VMNodeScrape" && try(object.spec.path, "") == "/metrics"
      ]).spec.metricRelabelConfigs[0].regex == "^(kubelet_volume_stats.*|volume_operation_total_seconds.*)$",
      one([
        for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : object
        if try(object.kind, "") == "VMNodeScrape" && try(object.spec.path, "") == "/metrics/cadvisor"
      ]).spec.metricRelabelConfigs[0].regex == "^(container_cpu_.*|container_memory_.*|container_network_.*|container_fs_.*)$",
      length([
        for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : object
        if try(object.kind, "") == "VMNodeScrape" && try(object.spec.path, "") == "/metrics/resource"
      ]) == 0,
    ])
    error_message = "Victoria mode must render authenticated native kubelet and cAdvisor discovery, with the resource endpoint opt-in."
  }
}

run "victoria_mode_preserves_custom_scrape_job" {
  command = plan

  module {
    source = "../../modules/victoria-metrics"
  }

  variables {
    operator_enabled              = true
    namespace                     = "monitoring"
    configs                       = {}
    agent_enabled                 = true
    agent_resource_scrape_enabled = true
    agent_extra_scrape_configs = [{
      job_name = "custom-job"
      static_configs = [{
        targets = ["example:9090"]
      }]
    }]
  }

  assert {
    condition = yamldecode(one([
      for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : object
      if try(object.kind, "") == "VMAgent"
    ]).spec.inlineScrapeConfig)[0].job_name == "custom-job"
    error_message = "The supplied non-secret scrape job must be preserved exactly."
  }

  assert {
    condition = alltrue([
      one([
        for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : object
        if try(object.kind, "") == "VMNodeScrape" && try(object.spec.path, "") == "/metrics/resource"
      ]).metadata.name == "victoria-metrics-agent-resource",
      one([
        for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : object
        if try(object.kind, "") == "VMNodeScrape" && try(object.spec.path, "") == "/metrics/resource"
      ]).spec.metricRelabelConfigs[0].regex == "^(container_cpu_.*|container_memory_.*|pod_cpu_usage_seconds_total|pod_memory_working_set_bytes)$",
    ])
    error_message = "The kubelet resource endpoint must be rendered only when explicitly enabled and keep only resource endpoint metrics."
  }
}

run "node_scrapes_route_known_metrics_and_preserve_custom_patterns" {
  command = plan

  module {
    source = "../../modules/victoria-metrics"
  }

  variables {
    operator_enabled              = true
    agent_enabled                 = true
    agent_resource_scrape_enabled = true
    agent_kubelet_metrics = [
      "container_cpu_.*",
      "kube_pod_container_status_.*",
      "kube_pod_resource_request",
      "custom_node_metric_.*",
    ]
  }

  assert {
    condition = toset([
      for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : "${object.spec.path}=${object.spec.metricRelabelConfigs[0].regex}"
      if try(object.kind, "") == "VMNodeScrape"
      ]) == toset([
      "/metrics=^(custom_node_metric_.*)$",
      "/metrics/cadvisor=^(container_cpu_.*|custom_node_metric_.*)$",
      "/metrics/resource=^(container_cpu_.*|custom_node_metric_.*)$",
    ])
    error_message = "Known node metrics must be routed by endpoint, known KSM/scheduler metrics excluded, and unknown caller patterns preserved on every endpoint."
  }

  assert {
    condition = alltrue([
      for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : alltrue([
        object.spec.tlsConfig.insecureSkipVerify == true,
        !contains(keys(object.spec.tlsConfig), "caFile"),
      ])
      if try(object.kind, "") == "VMNodeScrape"
    ])
    error_message = "Every native node endpoint must express skip-verification without an unused CA file."
  }
}

run "protected_victoria_metrics_agent_values_are_selector_owned" {
  command = plan

  module {
    source = "../../modules/victoria-metrics"
  }

  variables {
    operator_enabled = true
    agent_enabled    = true
    agent_extra_configs = {
      replicaCount                   = 9
      selectAllByDefault             = false
      remoteWrite                    = [{ url = "http://wrong-destination" }]
      inlineScrapeConfig             = "- job_name: wrong"
      podScrapeSelector              = { matchLabels = { team = "wrong" } }
      podScrapeNamespaceSelector     = { matchNames = ["wrong"] }
      serviceScrapeSelector          = { matchLabels = { team = "wrong" } }
      serviceScrapeNamespaceSelector = { matchNames = ["wrong"] }
      nodeScrapeSelector             = { matchLabels = { team = "wrong" } }
      nodeScrapeNamespaceSelector    = { matchNames = ["wrong"] }
    }
  }

  assert {
    condition = alltrue([
      one([
        for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : object
        if try(object.kind, "") == "VMAgent"
      ]).spec.replicaCount == 1,
      one([
        for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : object
        if try(object.kind, "") == "VMAgent"
      ]).spec.selectAllByDefault == true,
      one([
        for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : object
        if try(object.kind, "") == "VMAgent"
      ]).spec.remoteWrite[0].url == "http://victoria-metrics-victoria-metrics-cluster-vminsert.monitoring.svc.cluster.local:8480/insert/0/prometheus/api/v1/write",
      length(yamldecode(one([
        for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : object
        if try(object.kind, "") == "VMAgent"
      ]).spec.inlineScrapeConfig)) == 0,
      !contains(keys(one([
        for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : object
        if try(object.kind, "") == "VMAgent"
      ]).spec), "podScrapeSelector"),
      !contains(keys(one([
        for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : object
        if try(object.kind, "") == "VMAgent"
      ]).spec), "podScrapeNamespaceSelector"),
      !contains(keys(one([
        for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : object
        if try(object.kind, "") == "VMAgent"
      ]).spec), "serviceScrapeSelector"),
      !contains(keys(one([
        for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : object
        if try(object.kind, "") == "VMAgent"
      ]).spec), "serviceScrapeNamespaceSelector"),
      !contains(keys(one([
        for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : object
        if try(object.kind, "") == "VMAgent"
      ]).spec), "nodeScrapeSelector"),
      !contains(keys(one([
        for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : object
        if try(object.kind, "") == "VMAgent"
      ]).spec), "nodeScrapeNamespaceSelector"),
    ])
    error_message = "Raw VMAgent selectors must not narrow converted or native scrape discovery."
  }
}

run "vmagent_resource_overrides_are_merged" {
  command = plan

  module {
    source = "../../modules/victoria-metrics"
  }

  variables {
    operator_enabled = true
    agent_enabled    = true
    agent_extra_configs = {
      resources = {
        requests = { cpu = "1500m" }
        limits   = { memory = "2Gi" }
      }
      extraArgs = {
        "remoteWrite.queues"       = "24"
        "promscrape.maxScrapeSize" = "32MiB"
      }
    }
  }

  assert {
    condition = alltrue([
      one([
        for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : object
        if try(object.kind, "") == "VMAgent"
      ]).spec.resources.requests.cpu == "1500m",
      one([
        for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : object
        if try(object.kind, "") == "VMAgent"
      ]).spec.resources.requests.memory == "512Mi",
      one([
        for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : object
        if try(object.kind, "") == "VMAgent"
      ]).spec.resources.limits.cpu == "2",
      one([
        for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : object
        if try(object.kind, "") == "VMAgent"
      ]).spec.resources.limits.memory == "2Gi",
      one([
        for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : object
        if try(object.kind, "") == "VMAgent"
      ]).spec.extraArgs["remoteWrite.queues"] == "24",
      one([
        for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : object
        if try(object.kind, "") == "VMAgent"
      ]).spec.extraArgs["promscrape.maxScrapeSize"] == "32MiB",
    ])
    error_message = "Partial VMAgent resource and extra-argument overrides must retain every unspecified operational default."
  }
}

run "custom_kube_state_metrics_identity_is_exact" {
  command = plan

  module {
    source = "../../modules/victoria-metrics"
  }

  variables {
    operator_enabled                      = true
    namespace                             = "metrics-system"
    agent_enabled                         = true
    agent_kube_state_metrics_enabled      = true
    agent_kube_state_metrics_namespace    = "observability"
    agent_kube_state_metrics_release_name = "state-exporter"
    agent_kube_state_metrics_fullname     = "custom-state-metrics"
  }

  assert {
    condition = alltrue([
      length([
        for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : object
        if try(object.kind, "") == "VMServiceScrape"
      ]) == 1,
      one([
        for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : object
        if try(object.kind, "") == "VMServiceScrape"
      ]).metadata.name == "custom-state-metrics-victoria-metrics",
      one([
        for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : object
        if try(object.kind, "") == "VMServiceScrape"
      ]).metadata.namespace == "observability",
      one([
        for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : object
        if try(object.kind, "") == "VMServiceScrape"
      ]).spec.namespaceSelector.matchNames == ["observability"],
      one([
        for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : object
        if try(object.kind, "") == "VMServiceScrape"
      ]).spec.selector.matchLabels["app.kubernetes.io/name"] == "kube-state-metrics",
      one([
        for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : object
        if try(object.kind, "") == "VMServiceScrape"
      ]).spec.selector.matchLabels["app.kubernetes.io/instance"] == "state-exporter",
      one([
        for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : object
        if try(object.kind, "") == "VMServiceScrape"
      ]).spec.endpoints[0].port == "http",
      one([
        for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : object
        if try(object.kind, "") == "VMServiceScrape"
      ]).spec.endpoints[0].honorLabels == true,
      one([
        for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : object
        if try(object.kind, "") == "VMServiceScrape"
      ]).spec.endpoints[0].max_scrape_size == "32MiB",
    ])
    error_message = "The native KSM object must use the caller's resolved namespace, release label, and fullname."
  }
}

run "prometheus_mode_does_not_generate_native_ksm" {
  command = plan

  module {
    source = "../../modules/victoria-metrics"
  }

  variables {
    operator_enabled = true
    agent_enabled    = false
  }

  assert {
    condition = length([
      for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : object
      if try(object.kind, "") == "VMServiceScrape"
    ]) == 0
    error_message = "Prometheus mode must not render a native KSM object."
  }
}

run "vmagent_preserves_caller_kube_state_metrics_job" {
  command = plan

  module {
    source = "../../modules/victoria-metrics"
  }

  variables {
    operator_enabled = true
    agent_enabled    = true
    agent_extra_scrape_configs = [{
      job_name     = "kube-state-metrics"
      honor_labels = false
      static_configs = [{
        targets = ["custom-kube-state-metrics.example:8080"]
      }]
    }]
  }

  assert {
    condition = alltrue([
      length([
        for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : object
        if try(object.kind, "") == "VMServiceScrape"
      ]) == 0,
      length(yamldecode(one([
        for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : object
        if try(object.kind, "") == "VMAgent"
      ]).spec.inlineScrapeConfig)) == 1,
      yamldecode(one([
        for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : object
        if try(object.kind, "") == "VMAgent"
      ]).spec.inlineScrapeConfig)[0].static_configs[0].targets == ["custom-kube-state-metrics.example:8080"],
      yamldecode(one([
        for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : object
        if try(object.kind, "") == "VMAgent"
      ]).spec.inlineScrapeConfig)[0].honor_labels == false,
      !contains(keys(yamldecode(one([
        for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : object
        if try(object.kind, "") == "VMAgent"
      ]).spec.inlineScrapeConfig)[0]), "max_scrape_size"),
    ])
    error_message = "A caller-owned KSM job must suppress the native object and remain unchanged."
  }
}

run "caller_owned_service_jobs_survive_native_scrape_opt_outs" {
  command = plan

  module {
    source = "../../modules/victoria-metrics"
  }

  variables {
    operator_enabled                 = true
    agent_enabled                    = true
    agent_kubelet_scrape_enabled     = false
    agent_cadvisor_scrape_enabled    = false
    agent_kube_state_metrics_enabled = false
    agent_node_exporter_enabled      = false
    agent_tempo_enabled              = false
    agent_loki_enabled               = false
    agent_extra_scrape_configs = [
      {
        job_name = "kube-state-metrics"
        static_configs = [{
          targets = ["kube-state-metrics.monitoring.svc.cluster.local:8080"]
        }]
      },
      {
        job_name = "custom-node-exporter"
        static_configs = [{
          targets = ["node-exporter.monitoring.svc.cluster.local:9100"]
        }]
      },
      {
        job_name = "custom-tempo"
        static_configs = [{
          targets = ["tempo.monitoring.svc.cluster.local:3100"]
        }]
      },
      {
        job_name = "custom-loki"
        static_configs = [{
          targets = ["loki.monitoring.svc.cluster.local:3100"]
        }]
      },
    ]
  }

  assert {
    condition = alltrue([
      length([
        for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : object
        if try(object.kind, "") == "VMServiceScrape"
      ]) == 0,
      [
        for scrape_config in yamldecode(one([
          for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : object
          if try(object.kind, "") == "VMAgent"
        ]).spec.inlineScrapeConfig) : scrape_config.job_name
        ] == [
        "kube-state-metrics",
        "custom-node-exporter",
        "custom-tempo",
        "custom-loki",
      ],
    ])
    error_message = "Disabling child-managed service scrapes must preserve every caller-owned inline job in order."
  }
}

run "victoria_metrics_cluster_resource_defaults" {
  command = plan

  module {
    source = "../../modules/victoria-metrics"
  }

  variables {
    operator_enabled = true
    configs          = {}
  }

  assert {
    condition = alltrue([
      try(jsondecode(helm_release.victoria_metrics.values[0]).vminsert.resources.requests.cpu == "500m", false),
      try(jsondecode(helm_release.victoria_metrics.values[0]).vminsert.resources.requests.memory == "512Mi", false),
      try(jsondecode(helm_release.victoria_metrics.values[0]).vminsert.resources.limits.cpu == "2", false),
      try(jsondecode(helm_release.victoria_metrics.values[0]).vminsert.resources.limits.memory == "1Gi", false),
      try(jsondecode(helm_release.victoria_metrics.values[0]).vmstorage.resources.requests.cpu == "500m", false),
      try(jsondecode(helm_release.victoria_metrics.values[0]).vmstorage.resources.requests.memory == "1Gi", false),
      try(jsondecode(helm_release.victoria_metrics.values[0]).vmstorage.resources.limits.cpu == "1", false),
      try(jsondecode(helm_release.victoria_metrics.values[0]).vmstorage.resources.limits.memory == "2Gi", false),
    ])
    error_message = "VictoriaMetrics cluster defaults must provide enough vminsert and vmstorage headroom for the observed load."
  }
}

run "victoria_metrics_cluster_service_contract_is_protected" {
  command = plan

  module {
    source = "../../modules/victoria-metrics"
  }

  variables {
    operator_enabled = true
    release_name     = "victoria-metrics"
    configs          = {}
    extra_configs = {
      nameOverride = "wrong-cluster-name"
      vminsert = {
        enabled          = false
        name             = "wrong-vminsert"
        fullnameOverride = "wrong-vminsert-fullname"
        ports            = { name = "wrong" }
        extraArgs        = { httpListenAddr = ":9999" }
        service = {
          enabled     = false
          servicePort = 9999
          targetPort  = "wrong"
          type        = "ExternalName"
        }
        serviceMonitor = {
          enabled = true
        }
      }
      vmselect = {
        enabled          = false
        name             = "wrong-vmselect"
        fullnameOverride = "wrong-vmselect-fullname"
        ports            = { name = "wrong" }
        extraArgs        = { httpListenAddr = ":9998" }
        service = {
          enabled     = false
          servicePort = 9998
          targetPort  = "wrong"
          type        = "ExternalName"
        }
        serviceMonitor = {
          enabled = true
        }
      }
      vmstorage = {
        serviceMonitor = {
          enabled = true
        }
      }
      vmauth = {
        serviceMonitor = {
          enabled = true
        }
      }
    }
  }

  assert {
    condition = try(alltrue([
      !contains(keys(jsondecode(helm_release.victoria_metrics.values[2])), "nameOverride"),
      jsondecode(helm_release.victoria_metrics.values[2]).vminsert.enabled == true,
      !contains(keys(jsondecode(helm_release.victoria_metrics.values[2]).vminsert), "name"),
      jsondecode(helm_release.victoria_metrics.values[2]).vminsert.fullnameOverride == "victoria-metrics-victoria-metrics-cluster-vminsert",
      jsondecode(helm_release.victoria_metrics.values[2]).vminsert.ports.name == "http",
      jsondecode(helm_release.victoria_metrics.values[2]).vminsert.extraArgs.httpListenAddr == ":8480",
      jsondecode(helm_release.victoria_metrics.values[2]).vminsert.service.enabled == true,
      jsondecode(helm_release.victoria_metrics.values[2]).vminsert.service.servicePort == 8480,
      jsondecode(helm_release.victoria_metrics.values[2]).vminsert.service.targetPort == "http",
      jsondecode(helm_release.victoria_metrics.values[2]).vminsert.service.type == "ClusterIP",
      jsondecode(helm_release.victoria_metrics.values[2]).vminsert.serviceMonitor.enabled == false,
      jsondecode(helm_release.victoria_metrics.values[2]).vmselect.enabled == true,
      !contains(keys(jsondecode(helm_release.victoria_metrics.values[2]).vmselect), "name"),
      jsondecode(helm_release.victoria_metrics.values[2]).vmselect.fullnameOverride == "victoria-metrics-victoria-metrics-cluster-vmselect",
      jsondecode(helm_release.victoria_metrics.values[2]).vmselect.ports.name == "http",
      jsondecode(helm_release.victoria_metrics.values[2]).vmselect.extraArgs.httpListenAddr == ":8481",
      jsondecode(helm_release.victoria_metrics.values[2]).vmselect.service.enabled == true,
      jsondecode(helm_release.victoria_metrics.values[2]).vmselect.service.servicePort == 8481,
      jsondecode(helm_release.victoria_metrics.values[2]).vmselect.service.targetPort == "http",
      jsondecode(helm_release.victoria_metrics.values[2]).vmselect.service.type == "ClusterIP",
      jsondecode(helm_release.victoria_metrics.values[2]).vmselect.serviceMonitor.enabled == false,
      jsondecode(helm_release.victoria_metrics.values[2]).vmstorage.serviceMonitor.enabled == false,
      jsondecode(helm_release.victoria_metrics.values[2]).vmauth.serviceMonitor.enabled == false,
    ]), false)
    error_message = "Raw cluster overrides must not invalidate the selector-owned vminsert remote-write and vmselect query endpoints."
  }
}

run "prometheus_mode_preserves_vm_storage_identity" {
  command = plan

  module {
    source = "../../modules/victoria-metrics"
  }

  variables {
    operator_enabled = true
    release_name     = "stable-vm"
    agent_enabled    = false
    configs = {
      retention_period = "45d"
      vmstorage = {
        replica_count = 4
        storage_class = "gp3"
        storage_size  = "250Gi"
        access_modes  = ["ReadWriteOnce"]
      }
    }
  }

  assert {
    condition = alltrue([
      helm_release.victoria_metrics.name == "stable-vm",
      jsondecode(helm_release.victoria_metrics.values[0]).vmstorage.retentionPeriod == "45d",
      jsondecode(helm_release.victoria_metrics.values[0]).vmstorage.replicaCount == 4,
      jsondecode(helm_release.victoria_metrics.values[0]).vmstorage.persistentVolume.storageClassName == "gp3",
      jsondecode(helm_release.victoria_metrics.values[0]).vmstorage.persistentVolume.size == "250Gi",
      jsondecode(helm_release.victoria_metrics.values[0]).vmstorage.persistentVolume.accessModes == ["ReadWriteOnce"],
    ])
    error_message = "Prometheus mode must retain the requested VictoriaMetrics storage identity."
  }
}

run "victoria_mode_preserves_vm_storage_identity" {
  command = plan

  module {
    source = "../../modules/victoria-metrics"
  }

  variables {
    operator_enabled = true
    release_name     = "stable-vm"
    agent_enabled    = true
    configs = {
      retention_period = "45d"
      vmstorage = {
        replica_count = 4
        storage_class = "gp3"
        storage_size  = "250Gi"
        access_modes  = ["ReadWriteOnce"]
      }
    }
  }

  assert {
    condition = alltrue([
      helm_release.victoria_metrics.name == "stable-vm",
      jsondecode(helm_release.victoria_metrics.values[0]).vmstorage.retentionPeriod == "45d",
      jsondecode(helm_release.victoria_metrics.values[0]).vmstorage.replicaCount == 4,
      jsondecode(helm_release.victoria_metrics.values[0]).vmstorage.persistentVolume.storageClassName == "gp3",
      jsondecode(helm_release.victoria_metrics.values[0]).vmstorage.persistentVolume.size == "250Gi",
      jsondecode(helm_release.victoria_metrics.values[0]).vmstorage.persistentVolume.accessModes == ["ReadWriteOnce"],
      one([
        for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : object
        if try(object.kind, "") == "VMAgent"
      ]).spec.remoteWrite[0].url == "http://stable-vm-victoria-metrics-cluster-vminsert.monitoring.svc.cluster.local:8480/insert/0/prometheus/api/v1/write",
    ])
    error_message = "Victoria mode must retain the same VictoriaMetrics storage identity."
  }
}

run "standalone_vm_generates_kubernetes_component_discovery" {
  command = plan

  module {
    source = "../../modules/victoria-metrics"
  }

  variables {
    operator_enabled                 = true
    namespace                        = "monitoring"
    agent_enabled                    = true
    agent_standalone                 = true
    agent_kube_state_metrics_enabled = false
    agent_node_exporter_enabled      = false
  }

  assert {
    condition = alltrue([
      toset([
        for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : object.metadata.name
        if try(object.kind, "") == "Service"
        ]) == toset([
        "victoria-metrics-agent-coredns",
        "victoria-metrics-agent-kube-proxy",
        "victoria-metrics-agent-kube-etcd",
      ]),
      toset([
        for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : object.metadata.name
        if try(object.kind, "") == "VMServiceScrape"
        ]) == toset([
        "victoria-metrics-agent-coredns-victoria-metrics",
        "victoria-metrics-agent-kube-proxy-victoria-metrics",
        "victoria-metrics-agent-kube-etcd-victoria-metrics",
      ]),
      !contains([
        for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : object.metadata.name
      ], "victoria-metrics-agent-kube-apiserver-victoria-metrics"),
      length([
        for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : object
        if startswith(try(object.apiVersion, ""), "monitoring.coreos.com/")
      ]) == 0,
    ])
    error_message = "Standalone VictoriaMetrics must render three safe-default Kubernetes component Service/VMServiceScrape pairs, with authenticated control-plane targets and API server opt-in."
  }

  assert {
    condition = alltrue([
      alltrue([
        for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : alltrue([
          object.metadata.namespace == "kube-system",
          object.metadata.labels["monitoring.dasmeta.com/component"] != "",
          object.metadata.labels.jobLabel != "",
          object.spec.clusterIP == "None",
          object.spec.type == "ClusterIP",
          object.spec.ports[0].name == "http-metrics",
          object.spec.ports[0].protocol == "TCP",
          object.spec.ports[0].targetPort == object.spec.ports[0].port,
        ]) if try(object.kind, "") == "Service"
      ]),
      alltrue([
        for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : alltrue([
          object.metadata.namespace == "monitoring",
          object.spec.namespaceSelector.matchNames == ["kube-system"],
          object.spec.jobLabel == "jobLabel",
          object.spec.endpoints[0].port == "http-metrics",
          object.spec.endpoints[0].path == "/metrics",
          object.spec.endpoints[0].interval == "30s",
          object.spec.endpoints[0].scrapeTimeout == "10s",
        ]) if try(object.kind, "") == "VMServiceScrape"
      ]),
    ])
    error_message = "Standalone component discovery must use stable namespaces, labels, ports, and scrape timing."
  }

  assert {
    condition = alltrue([
      one([
        for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : object
        if try(object.metadata.name, "") == "victoria-metrics-agent-coredns"
      ]).spec.selector == { "k8s-app" = "kube-dns" },
      one([
        for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : object
        if try(object.metadata.name, "") == "victoria-metrics-agent-coredns"
      ]).spec.ports[0].port == 9153,
      one([
        for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : object
        if try(object.metadata.name, "") == "victoria-metrics-agent-coredns-victoria-metrics"
      ]).spec.endpoints[0].scheme == "http",
      try(one([
        for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : object
        if try(object.metadata.name, "") == "victoria-metrics-agent-coredns-victoria-metrics"
      ]).spec.endpoints[0].bearerTokenFile, null) == null,
      one([
        for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : object
        if try(object.metadata.name, "") == "victoria-metrics-agent-coredns-victoria-metrics"
        ]).spec.endpoints[0].metricRelabelConfigs[0] == {
        source_labels = ["__name__"]
        regex         = "^go_.*"
        action        = "drop"
      },
      one([
        for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : object
        if try(object.metadata.name, "") == "victoria-metrics-agent-kube-proxy"
      ]).spec.selector == { "k8s-app" = "kube-proxy" },
      one([
        for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : object
        if try(object.metadata.name, "") == "victoria-metrics-agent-kube-proxy"
      ]).spec.ports[0].port == 10249,
      one([
        for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : object
        if try(object.metadata.name, "") == "victoria-metrics-agent-kube-proxy-victoria-metrics"
      ]).spec.endpoints[0].metricRelabelConfigs[0].regex == "^go_.*",
      try(one([
        for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : object
        if try(object.metadata.name, "") == "victoria-metrics-agent-kube-proxy-victoria-metrics"
      ]).spec.endpoints[0].bearerTokenFile, null) == null,
    ])
    error_message = "CoreDNS and kube-proxy discovery must match kube-prometheus-stack selectors, ports, and go metric filtering."
  }

  assert {
    condition = alltrue([
      one([
        for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : object
        if try(object.metadata.name, "") == "victoria-metrics-agent-kube-etcd"
      ]).spec.selector == { component = "etcd" },
      one([
        for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : object
        if try(object.metadata.name, "") == "victoria-metrics-agent-kube-etcd"
      ]).spec.ports[0].port == 2381,
      one([
        for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : object
        if try(object.metadata.name, "") == "victoria-metrics-agent-kube-etcd-victoria-metrics"
      ]).spec.endpoints[0].scheme == "http",
      try(one([
        for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : object
        if try(object.metadata.name, "") == "victoria-metrics-agent-kube-etcd-victoria-metrics"
      ]).spec.endpoints[0].bearerTokenFile, null) == null,
    ])
    error_message = "Default etcd discovery must preserve its selector and port while omitting credentials from its HTTP target."
  }
}

run "authenticated_component_requires_explicit_tls_configuration" {
  command = plan

  module {
    source = "../../modules/victoria-metrics"
  }

  variables {
    operator_enabled                 = true
    agent_enabled                    = true
    agent_standalone                 = true
    agent_kube_state_metrics_enabled = false
    agent_node_exporter_enabled      = false
    agent_kubernetes_component_scrapes = {
      core_dns           = false
      kube_proxy         = false
      controller_manager = true
      scheduler          = false
      etcd               = false
    }
  }

  expect_failures = [var.agent_kubernetes_component_scrapes]
}

run "standalone_vm_component_overrides_and_api_server_are_exact" {
  command = plan

  module {
    source = "../../modules/victoria-metrics"
  }

  variables {
    operator_enabled                 = true
    namespace                        = "metrics-system"
    agent_enabled                    = true
    agent_standalone                 = true
    agent_kube_state_metrics_enabled = false
    agent_node_exporter_enabled      = false
    agent_kubernetes_component_scrapes = {
      namespace            = "platform-system"
      api_server_namespace = "cluster-api"
      api_server           = true
      core_dns             = true
      kube_proxy           = false
      controller_manager   = true
      scheduler            = true
      etcd                 = false
      controller_manager_tls = {
        ca_file              = "/etc/vmagent/controller-manager/ca.crt"
        server_name          = "controller-manager.platform-system.svc"
        insecure_skip_verify = false
      }
      scheduler_tls = {
        ca_file              = "/etc/vmagent/scheduler/ca.crt"
        server_name          = "scheduler.platform-system.svc"
        insecure_skip_verify = false
      }
    }
  }

  assert {
    condition = alltrue([
      length([
        for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : object
        if try(object.kind, "") == "Service"
      ]) == 3,
      one([
        for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : object
        if try(object.metadata.name, "") == "victoria-metrics-agent-coredns"
      ]).metadata.name == "victoria-metrics-agent-coredns",
      one([
        for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : object
        if try(object.metadata.name, "") == "victoria-metrics-agent-coredns"
      ]).metadata.namespace == "platform-system",
      !contains([
        for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : object.metadata.name
      ], "victoria-metrics-agent-kube-proxy"),
    ])
    error_message = "Component namespace and per-component disable switches must control both discovery objects."
  }

  assert {
    condition = alltrue([
      length([
        for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : object
        if try(object.kind, "") == "VMServiceScrape"
      ]) == 4,
      one([
        for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : object
        if try(object.metadata.name, "") == "victoria-metrics-agent-coredns-victoria-metrics"
      ]).metadata.namespace == "metrics-system",
      one([
        for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : object
        if try(object.metadata.name, "") == "victoria-metrics-agent-coredns-victoria-metrics"
      ]).spec.namespaceSelector.matchNames == ["platform-system"],
      one([
        for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : object
        if try(object.metadata.name, "") == "victoria-metrics-agent-kube-apiserver-victoria-metrics"
      ]).metadata.namespace == "metrics-system",
      one([
        for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : object
        if try(object.metadata.name, "") == "victoria-metrics-agent-kube-apiserver-victoria-metrics"
      ]).spec.namespaceSelector.matchNames == ["cluster-api"],
      one([
        for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : object
        if try(object.metadata.name, "") == "victoria-metrics-agent-kube-apiserver-victoria-metrics"
        ]).spec.selector.matchLabels == {
        component = "apiserver"
        provider  = "kubernetes"
      },
      one([
        for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : object
        if try(object.metadata.name, "") == "victoria-metrics-agent-kube-apiserver-victoria-metrics"
      ]).spec.jobLabel == "component",
      one([
        for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : object
        if try(object.metadata.name, "") == "victoria-metrics-agent-kube-controller-manager-victoria-metrics"
      ]).spec.endpoints[0].tlsConfig.caFile == "/etc/vmagent/controller-manager/ca.crt",
      one([
        for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : object
        if try(object.metadata.name, "") == "victoria-metrics-agent-kube-controller-manager-victoria-metrics"
      ]).spec.endpoints[0].tlsConfig.serverName == "controller-manager.platform-system.svc",
      one([
        for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : object
        if try(object.metadata.name, "") == "victoria-metrics-agent-kube-controller-manager-victoria-metrics"
      ]).spec.endpoints[0].tlsConfig.insecureSkipVerify == false,
      one([
        for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : object
        if try(object.metadata.name, "") == "victoria-metrics-agent-kube-scheduler-victoria-metrics"
      ]).spec.endpoints[0].tlsConfig.caFile == "/etc/vmagent/scheduler/ca.crt",
      one([
        for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : object
        if try(object.metadata.name, "") == "victoria-metrics-agent-kube-scheduler-victoria-metrics"
      ]).spec.endpoints[0].tlsConfig.serverName == "scheduler.platform-system.svc",
      one([
        for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : object
        if try(object.metadata.name, "") == "victoria-metrics-agent-kube-scheduler-victoria-metrics"
      ]).spec.endpoints[0].tlsConfig.insecureSkipVerify == false,
    ])
    error_message = "Component and API-server VMServiceScrapes must honor target namespaces and component-specific verified TLS settings."
  }

  assert {
    condition = alltrue([
      one([
        for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : object
        if try(object.metadata.name, "") == "victoria-metrics-agent-kube-apiserver-victoria-metrics"
      ]).spec.endpoints[0].port == "https",
      one([
        for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : object
        if try(object.metadata.name, "") == "victoria-metrics-agent-kube-apiserver-victoria-metrics"
      ]).spec.endpoints[0].scheme == "https",
      one([
        for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : object
        if try(object.metadata.name, "") == "victoria-metrics-agent-kube-apiserver-victoria-metrics"
      ]).spec.endpoints[0].path == "/metrics",
      one([
        for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : object
        if try(object.metadata.name, "") == "victoria-metrics-agent-kube-apiserver-victoria-metrics"
      ]).spec.endpoints[0].interval == "30s",
      one([
        for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : object
        if try(object.metadata.name, "") == "victoria-metrics-agent-kube-apiserver-victoria-metrics"
      ]).spec.endpoints[0].scrapeTimeout == "10s",
      one([
        for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : object
        if try(object.metadata.name, "") == "victoria-metrics-agent-kube-apiserver-victoria-metrics"
      ]).spec.endpoints[0].bearerTokenFile == "/var/run/secrets/kubernetes.io/serviceaccount/token",
      one([
        for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : object
        if try(object.metadata.name, "") == "victoria-metrics-agent-kube-apiserver-victoria-metrics"
      ]).spec.endpoints[0].tlsConfig.caFile == "/var/run/secrets/kubernetes.io/serviceaccount/ca.crt",
      one([
        for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : object
        if try(object.metadata.name, "") == "victoria-metrics-agent-kube-apiserver-victoria-metrics"
      ]).spec.endpoints[0].tlsConfig.serverName == "kubernetes",
      one([
        for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : object
        if try(object.metadata.name, "") == "victoria-metrics-agent-kube-apiserver-victoria-metrics"
      ]).spec.endpoints[0].tlsConfig.insecureSkipVerify == false,
      one([
        for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : object
        if try(object.metadata.name, "") == "victoria-metrics-agent-kube-apiserver-victoria-metrics"
      ]).spec.endpoints[0].metricRelabelConfigs[0].source_labels == ["__name__", "le"],
      one([
        for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : object
        if try(object.metadata.name, "") == "victoria-metrics-agent-kube-apiserver-victoria-metrics"
      ]).spec.endpoints[0].metricRelabelConfigs[0].regex == "(etcd_request|apiserver_request_slo|apiserver_request_sli|apiserver_request)_duration_seconds_bucket;(0\\.15|0\\.2|0\\.3|0\\.35|0\\.4|0\\.45|0\\.6|0\\.7|0\\.8|0\\.9|1\\.25|1\\.5|1\\.75|2|3|3\\.5|4|4\\.5|6|7|8|9|15|20|40|45|50)(\\.0)?",
      one([
        for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : object
        if try(object.metadata.name, "") == "victoria-metrics-agent-kube-apiserver-victoria-metrics"
      ]).spec.endpoints[0].metricRelabelConfigs[0].action == "drop",
    ])
    error_message = "API-server scraping must use the Kubernetes Service, service-account auth, verified TLS, and histogram filtering."
  }
}

run "dual_mode_does_not_generate_native_kubernetes_component_discovery" {
  command = plan

  module {
    source = "../../modules/victoria-metrics"
  }

  variables {
    operator_enabled                 = true
    agent_enabled                    = true
    agent_standalone                 = false
    agent_kube_state_metrics_enabled = false
    agent_node_exporter_enabled      = false
  }

  assert {
    condition = alltrue([
      length([
        for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : object
        if try(object.kind, "") == "Service"
      ]) == 0,
      length([
        for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : object
        if try(object.kind, "") == "VMServiceScrape"
      ]) == 0,
    ])
    error_message = "Dual mode must rely on converted kube-prometheus-stack monitors instead of duplicating native component discovery."
  }
}

run "standalone_component_names_remain_collision_safe" {
  command = plan

  module {
    source = "../../modules/victoria-metrics"
  }

  variables {
    operator_enabled                 = true
    agent_name                       = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.bbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
    agent_enabled                    = true
    agent_standalone                 = true
    agent_kubelet_scrape_enabled     = false
    agent_cadvisor_scrape_enabled    = false
    agent_kube_state_metrics_enabled = false
    agent_node_exporter_enabled      = false
    agent_kubernetes_component_scrapes = {
      core_dns           = true
      kube_proxy         = true
      controller_manager = false
      scheduler          = false
      etcd               = false
    }
  }

  assert {
    condition = alltrue([
      length(distinct([
        for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : object.metadata.name
        if try(object.kind, "") == "Service" || try(object.kind, "") == "VMServiceScrape"
      ])) == 4,
      alltrue([
        for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : alltrue([
          length(object.metadata.name) <= 63,
          can(regex("^[a-z0-9]([-a-z0-9]*[a-z0-9])?$", object.metadata.name)),
        ]) if try(object.kind, "") == "Service" || try(object.kind, "") == "VMServiceScrape"
      ]),
    ])
    error_message = "Long valid VMAgent names must produce distinct DNS-label-safe component Service and VMServiceScrape names."
  }
}
