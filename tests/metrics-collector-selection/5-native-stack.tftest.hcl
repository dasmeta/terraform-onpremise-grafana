mock_provider "helm" {}
mock_provider "grafana" {}
mock_provider "random" {}
mock_provider "time" {}

run "independent_node_exporter_prometheus_monitor_is_selector_owned" {
  command = plan

  module {
    source = "../../modules/node-exporter"
  }

  variables {
    namespace                  = "monitoring"
    release_name               = "node-exporter"
    fullname_override          = "prometheus-node-exporter"
    prometheus_monitor_enabled = true
    prometheus_release_name    = "prometheus"
    extra_configs = {
      fullnameOverride = "wrong-name"
      resources = {
        requests = { cpu = "1m", memory = "1Mi" }
        limits   = { cpu = "2m", memory = "2Mi" }
      }
      extraArgs = ["--collector.textfile.directory=/var/lib/node-exporter"]
      service = {
        port     = 9999
        portName = "wrong"
        annotations = {
          "prometheus.io/scrape" = "true"
          "example.com/keep"     = "yes"
        }
      }
      prometheus = {
        monitor = {
          enabled = false
        }
      }
    }
  }

  assert {
    condition = alltrue([
      helm_release.node_exporter.name == "node-exporter",
      helm_release.node_exporter.chart == "prometheus-node-exporter",
      helm_release.node_exporter.version == "4.47.1",
      helm_release.node_exporter.namespace == "monitoring",
      jsondecode(helm_release.node_exporter.values[1]).fullnameOverride == "prometheus-node-exporter",
      jsondecode(helm_release.node_exporter.values[1]).resources.requests.cpu == "100m",
      jsondecode(helm_release.node_exporter.values[1]).resources.requests.memory == "200Mi",
      jsondecode(helm_release.node_exporter.values[1]).resources.limits.cpu == "200m",
      jsondecode(helm_release.node_exporter.values[1]).resources.limits.memory == "500Mi",
      contains(jsondecode(helm_release.node_exporter.values[1]).extraArgs, "--web.disable-exporter-metrics"),
      contains(jsondecode(helm_release.node_exporter.values[1]).extraArgs, "--collector.textfile.directory=/var/lib/node-exporter"),
      jsondecode(helm_release.node_exporter.values[1]).service.port == 9100,
      jsondecode(helm_release.node_exporter.values[1]).service.targetPort == 9100,
      jsondecode(helm_release.node_exporter.values[1]).service.portName == "metrics",
      jsondecode(helm_release.node_exporter.values[1]).service.annotations["prometheus.io/scrape"] == "false",
      jsondecode(helm_release.node_exporter.values[1]).service.annotations["example.com/keep"] == "yes",
      jsondecode(helm_release.node_exporter.values[1]).prometheus.monitor.enabled == true,
      jsondecode(helm_release.node_exporter.values[1]).prometheus.monitor.additionalLabels.release == "prometheus",
      jsondecode(helm_release.node_exporter.values[1]).prometheus.monitor.selectorOverride["app.kubernetes.io/name"] == "prometheus-node-exporter",
      jsondecode(helm_release.node_exporter.values[1]).prometheus.monitor.selectorOverride["app.kubernetes.io/instance"] == "node-exporter",
      jsondecode(helm_release.node_exporter.values[1]).prometheus.monitor.metricRelabelings[0].sourceLabels == ["__name__"],
      jsondecode(helm_release.node_exporter.values[1]).prometheus.monitor.metricRelabelings[0].regex == "^go_.*",
      jsondecode(helm_release.node_exporter.values[1]).prometheus.monitor.metricRelabelings[0].action == "drop",
    ])
    error_message = "The independent node-exporter must retain stable identity/resources and exactly the selected Prometheus monitor path."
  }
}

run "independent_node_exporter_vm_mode_suppresses_prometheus_monitor" {
  command = plan

  module {
    source = "../../modules/node-exporter"
  }

  variables {
    prometheus_monitor_enabled = false
    extra_configs = {
      service = {
        annotations = {
          "prometheus.io/scrape" = "true"
        }
      }
      prometheus = {
        monitor = {
          enabled = true
        }
      }
    }
  }

  assert {
    condition = alltrue([
      jsondecode(helm_release.node_exporter.values[1]).service.annotations["prometheus.io/scrape"] == "false",
      jsondecode(helm_release.node_exporter.values[1]).prometheus.monitor.enabled == false,
    ])
    error_message = "VictoriaMetrics mode must not allow annotation scraping or a Prometheus ServiceMonitor for node-exporter."
  }
}

run "victoria_metrics_generates_native_node_exporter_scrape" {
  command = plan

  module {
    source = "../../modules/victoria-metrics"
  }

  variables {
    agent_enabled                    = true
    agent_kube_state_metrics_enabled = false
    agent_node_exporter_enabled      = true
    agent_node_exporter_namespace    = "observability"
    agent_node_exporter_release_name = "host-metrics"
    agent_node_exporter_fullname     = "custom-node-exporter"
  }

  assert {
    condition = alltrue([
      length([
        for object in jsondecode(helm_release.victoria_metrics_resources.values[0]).objects : object
        if try(object.kind, "") == "VMServiceScrape"
      ]) == 1,
      one([
        for object in jsondecode(helm_release.victoria_metrics_resources.values[0]).objects : object
        if try(object.kind, "") == "VMServiceScrape"
      ]).metadata.name == "custom-node-exporter-victoria-metrics",
      one([
        for object in jsondecode(helm_release.victoria_metrics_resources.values[0]).objects : object
        if try(object.kind, "") == "VMServiceScrape"
      ]).metadata.namespace == "observability",
      one([
        for object in jsondecode(helm_release.victoria_metrics_resources.values[0]).objects : object
        if try(object.kind, "") == "VMServiceScrape"
      ]).spec.namespaceSelector.matchNames == ["observability"],
      one([
        for object in jsondecode(helm_release.victoria_metrics_resources.values[0]).objects : object
        if try(object.kind, "") == "VMServiceScrape"
      ]).spec.selector.matchLabels["app.kubernetes.io/name"] == "prometheus-node-exporter",
      one([
        for object in jsondecode(helm_release.victoria_metrics_resources.values[0]).objects : object
        if try(object.kind, "") == "VMServiceScrape"
      ]).spec.selector.matchLabels["app.kubernetes.io/instance"] == "host-metrics",
      one([
        for object in jsondecode(helm_release.victoria_metrics_resources.values[0]).objects : object
        if try(object.kind, "") == "VMServiceScrape"
      ]).spec.endpoints[0].port == "metrics",
      one([
        for object in jsondecode(helm_release.victoria_metrics_resources.values[0]).objects : object
        if try(object.kind, "") == "VMServiceScrape"
      ]).spec.endpoints[0].metricRelabelConfigs[0].source_labels == ["__name__"],
      one([
        for object in jsondecode(helm_release.victoria_metrics_resources.values[0]).objects : object
        if try(object.kind, "") == "VMServiceScrape"
      ]).spec.endpoints[0].metricRelabelConfigs[0].regex == "^go_.*",
      one([
        for object in jsondecode(helm_release.victoria_metrics_resources.values[0]).objects : object
        if try(object.kind, "") == "VMServiceScrape"
      ]).spec.endpoints[0].metricRelabelConfigs[0].action == "drop",
    ])
    error_message = "VictoriaMetrics mode must discover the independent node-exporter through exactly one native VMServiceScrape."
  }
}

run "tempo_metrics_integration_is_selector_owned" {
  command = plan

  module {
    source = "../../modules/tempo"
  }

  variables {
    metrics_generator_remote_url = "http://vminsert.monitoring.svc.cluster.local:8480/insert/0/prometheus/api/v1/write"
    service_monitor_enabled      = false
    configs = {
      enable_service_monitor = true
      metrics_generator = {
        enabled    = true
        remote_url = null
      }
    }
    extra_configs = {
      tempo = {
        metricsGenerator = {
          remoteWriteUrl = "http://wrong-prometheus/api/v1/write"
        }
      }
      serviceMonitor = {
        enabled = true
      }
    }
  }

  assert {
    condition = alltrue([
      jsondecode(helm_release.tempo.values[2]).tempo.metricsGenerator.remoteWriteUrl == "http://vminsert.monitoring.svc.cluster.local:8480/insert/0/prometheus/api/v1/write",
      jsondecode(helm_release.tempo.values[2]).serviceMonitor.enabled == false,
      !output.service_monitor_enabled,
    ])
    error_message = "Tempo must use the selected write endpoint and must not create a Prometheus ServiceMonitor in VM mode."
  }
}

run "tempo_explicit_remote_url_is_preserved" {
  command = plan

  module {
    source = "../../modules/tempo"
  }

  variables {
    metrics_generator_remote_url = "https://metrics.example.test/api/v1/write"
    configs = {
      metrics_generator = {
        enabled    = true
        remote_url = "https://metrics.example.test/api/v1/write"
      }
    }
  }

  assert {
    condition     = jsondecode(helm_release.tempo.values[2]).tempo.metricsGenerator.remoteWriteUrl == "https://metrics.example.test/api/v1/write"
    error_message = "An explicit Tempo metrics-generator remote URL must remain unchanged."
  }
}

run "loki_prometheus_resources_are_selector_owned" {
  command = plan

  module {
    source = "../../modules/loki-stack"
  }

  variables {
    prometheus_monitor_enabled = false
    prometheus_rules_enabled   = false
    configs = {
      loki = {
        monitoring = {
          serviceMonitor = {
            enabled = true
          }
        }
        extra_configs = {
          monitoring = {
            serviceMonitor = { enabled = true }
            rules          = { enabled = true }
          }
        }
      }
      promtail = {
        enabled = false
      }
    }
  }

  assert {
    condition = alltrue([
      jsondecode(helm_release.loki.values[3]).monitoring.serviceMonitor.enabled == false,
      jsondecode(helm_release.loki.values[3]).monitoring.rules.enabled == false,
      output.release.name == "loki",
      output.release.namespace == "monitoring",
    ])
    error_message = "Loki must not render Prometheus ServiceMonitor or PrometheusRule resources in VictoriaMetrics mode."
  }
}

run "grafana_metrics_integration_is_selector_owned" {
  command = plan

  module {
    source = "../../modules/grafana"
  }

  variables {
    default_metrics_datasource_uid = "victoriametrics"
    prometheus_monitor_enabled     = false
    grafana_admin_password         = "test-only-placeholder"
    configs                        = {}
    datasources = [{
      type = "tempo"
      name = "Tempo"
    }]
    extra_configs = {
      serviceMonitor = {
        enabled = true
      }
    }
  }

  assert {
    condition = alltrue([
      jsondecode(output.datasources.Tempo.encoded_json).tracesToMetrics.datasourceUid == "victoriametrics",
      jsondecode(helm_release.grafana.values[2]).serviceMonitor.enabled == false,
    ])
    error_message = "Grafana traces-to-metrics must follow the selected datasource and raw values must not enable a Prometheus monitor in VM mode."
  }
}

run "victoria_metrics_generates_native_component_scrapes" {
  command = plan

  module {
    source = "../../modules/victoria-metrics"
  }

  variables {
    agent_enabled                    = true
    agent_kube_state_metrics_enabled = false
    agent_node_exporter_enabled      = false
    agent_tempo_enabled              = true
    agent_tempo_namespace            = "observability"
    agent_tempo_release_name         = "traces"
    agent_loki_enabled               = true
    agent_loki_namespace             = "logs"
    agent_loki_release_name          = "logs-backend"
  }

  assert {
    condition = alltrue([
      length([
        for object in jsondecode(helm_release.victoria_metrics_resources.values[0]).objects : object
        if try(object.kind, "") == "VMServiceScrape"
      ]) == 2,
      one([
        for object in jsondecode(helm_release.victoria_metrics_resources.values[0]).objects : object
        if try(object.kind, "") == "VMServiceScrape" && try(object.metadata.name, "") == "traces-victoria-metrics"
      ]).metadata.namespace == "observability",
      one([
        for object in jsondecode(helm_release.victoria_metrics_resources.values[0]).objects : object
        if try(object.kind, "") == "VMServiceScrape" && try(object.metadata.name, "") == "traces-victoria-metrics"
      ]).spec.selector.matchLabels["app.kubernetes.io/name"] == "tempo",
      one([
        for object in jsondecode(helm_release.victoria_metrics_resources.values[0]).objects : object
        if try(object.kind, "") == "VMServiceScrape" && try(object.metadata.name, "") == "traces-victoria-metrics"
      ]).spec.selector.matchLabels["app.kubernetes.io/instance"] == "traces",
      one([
        for object in jsondecode(helm_release.victoria_metrics_resources.values[0]).objects : object
        if try(object.kind, "") == "VMServiceScrape" && try(object.metadata.name, "") == "traces-victoria-metrics"
      ]).spec.endpoints[0].port == "tempo-prom-metrics",
      one([
        for object in jsondecode(helm_release.victoria_metrics_resources.values[0]).objects : object
        if try(object.kind, "") == "VMServiceScrape" && try(object.metadata.name, "") == "logs-backend-victoria-metrics"
      ]).metadata.namespace == "logs",
      one([
        for object in jsondecode(helm_release.victoria_metrics_resources.values[0]).objects : object
        if try(object.kind, "") == "VMServiceScrape" && try(object.metadata.name, "") == "logs-backend-victoria-metrics"
      ]).spec.selector.matchLabels["app.kubernetes.io/name"] == "loki",
      one([
        for object in jsondecode(helm_release.victoria_metrics_resources.values[0]).objects : object
        if try(object.kind, "") == "VMServiceScrape" && try(object.metadata.name, "") == "logs-backend-victoria-metrics"
      ]).spec.selector.matchLabels["app.kubernetes.io/instance"] == "logs-backend",
      one([
        for object in jsondecode(helm_release.victoria_metrics_resources.values[0]).objects : object
        if try(object.kind, "") == "VMServiceScrape" && try(object.metadata.name, "") == "logs-backend-victoria-metrics"
      ]).spec.endpoints[0].port == "http-metrics",
      alltrue([
        for object in jsondecode(helm_release.victoria_metrics_resources.values[0]).objects : object.apiVersion == "operator.victoriametrics.com/v1beta1"
      ]),
    ])
    error_message = "VM-only module integrations must use native Tempo/Loki VMServiceScrapes and no Prometheus API objects."
  }
}

run "victoria_metrics_only_wires_all_module_integrations" {
  command = apply

  module {
    source = "../.."
  }

  variables {
    metrics_collector      = "victoria_metrics"
    grafana_admin_password = "test-only-placeholder"
    prometheus = {
      enabled = false
    }
    victoria_metrics = {
      enabled = true
    }
    grafana = {
      enabled = true
    }
    tempo = {
      enabled = true
    }
    loki_stack = {
      enabled = true
      promtail = {
        enabled = false
      }
    }
    alerts = {
      disk_capacity  = { enabled = false }
      rules          = []
      contact_points = null
      notifications  = null
    }
  }

  assert {
    condition = alltrue([
      output.metrics_collector_status.victoria_metrics_standalone,
      output.metrics_collector_status.selected_metrics_remote_write_url == "http://victoria-metrics-victoria-metrics-cluster-vminsert.monitoring.svc.cluster.local:8480/insert/0/prometheus/api/v1/write",
      output.metrics_collector_status.tempo_metrics_generator_remote_write_url == "http://victoria-metrics-victoria-metrics-cluster-vminsert.monitoring.svc.cluster.local:8480/insert/0/prometheus/api/v1/write",
      !output.metrics_collector_status.grafana_prometheus_monitor_enabled,
      !output.metrics_collector_status.tempo_prometheus_monitor_enabled,
      !output.metrics_collector_status.loki_prometheus_monitor_enabled,
      output.metrics_collector_status.vm_service_scrapes.kube_state_metrics,
      output.metrics_collector_status.vm_service_scrapes.node_exporter,
      output.metrics_collector_status.vm_service_scrapes.tempo,
      output.metrics_collector_status.vm_service_scrapes.loki,
      contains(keys(output.grafana.datasources), "VictoriaMetrics"),
      !contains(keys(output.grafana.datasources), "Prometheus"),
      tobool(output.grafana.datasources.VictoriaMetrics.is_default),
      jsondecode(output.grafana.datasources.Tempo.encoded_json).tracesToMetrics.datasourceUid == "victoriametrics",
    ])
    error_message = "A full VM-only root plan must route Grafana, Tempo, Loki, and both exporters exclusively through VictoriaMetrics."
  }
}

run "disabled_shared_exporters_create_no_workload_or_discovery" {
  command = apply

  module {
    source = "../.."
  }

  variables {
    metrics_collector      = "victoria_metrics"
    grafana_admin_password = "test-only-placeholder"
    prometheus             = { enabled = false }
    victoria_metrics       = { enabled = true }
    kube_state_metrics     = { enabled = false }
    node_exporter          = { enabled = false }
    grafana                = { enabled = false }
    tempo                  = { enabled = false }
    loki_stack             = { enabled = false }
    alerts = {
      disk_capacity  = { enabled = false }
      rules          = []
      contact_points = null
      notifications  = null
    }
  }

  assert {
    condition = alltrue([
      !output.metrics_collector_status.kube_state_metrics_installed,
      !output.metrics_collector_status.kube_state_metrics_prometheus_monitor_enabled,
      !output.metrics_collector_status.kube_state_metrics_vm_service_scrape_enabled,
      !output.metrics_collector_status.node_exporter_installed,
      !output.metrics_collector_status.node_exporter_prometheus_monitor_enabled,
      !output.metrics_collector_status.node_exporter_vm_service_scrape_enabled,
      !output.metrics_collector_status.vm_service_scrapes.kube_state_metrics,
      !output.metrics_collector_status.vm_service_scrapes.node_exporter,
      output.kube_state_metrics == null,
      output.node_exporter == null,
    ])
    error_message = "Explicitly disabled shared exporters must create neither workloads nor collector discovery definitions."
  }
}
