mock_provider "helm" {}
mock_provider "grafana" {}
mock_provider "time" {}

run "grafana_monitor_preserves_direct_child_extra_config" {
  command = plan

  module {
    source = "../../modules/grafana"
  }

  variables {
    grafana_admin_password = "test-password"
    extra_configs = {
      serviceMonitor = {
        enabled = true
      }
    }
  }

  assert {
    condition     = try(jsondecode(helm_release.grafana.values[2]).serviceMonitor.enabled == true, false)
    error_message = "A direct Grafana child caller must retain extra_configs.serviceMonitor.enabled when prometheus_monitor_enabled is omitted."
  }
}

run "grafana_monitor_explicit_disable_wins" {
  command = plan

  module {
    source = "../../modules/grafana"
  }

  variables {
    grafana_admin_password     = "test-password"
    prometheus_monitor_enabled = false
    extra_configs = {
      serviceMonitor = {
        enabled = true
      }
    }
  }

  assert {
    condition     = try(jsondecode(helm_release.grafana.values[2]).serviceMonitor.enabled == false, false)
    error_message = "An explicit selector-owned false value must disable the Grafana ServiceMonitor."
  }
}

run "grafana_monitor_explicit_enable_wins" {
  command = plan

  module {
    source = "../../modules/grafana"
  }

  variables {
    grafana_admin_password     = "test-password"
    prometheus_monitor_enabled = true
    extra_configs = {
      serviceMonitor = {
        enabled = false
      }
    }
  }

  assert {
    condition     = try(jsondecode(helm_release.grafana.values[2]).serviceMonitor.enabled == true, false)
    error_message = "An explicit selector-owned true value must enable the Grafana ServiceMonitor."
  }
}

run "prometheus_component_monitors_remain_available_for_conversion" {
  command = plan

  module {
    source = "../../modules/prometheus"
  }

  variables {
    collector_enabled = false
  }

  assert {
    condition = alltrue([
      helm_release.prometheus.chart == "kube-prometheus-stack",
      helm_release.prometheus.version == "75.8.0",
      alltrue([
        for value in helm_release.prometheus.values : alltrue([
          try(yamldecode(value).kubernetesServiceMonitors.enabled, true) != false,
          try(yamldecode(value).coreDns.enabled, true) != false,
          try(yamldecode(value).coreDns.service.enabled, true) != false,
          try(yamldecode(value).coreDns.serviceMonitor.enabled, true) != false,
          try(yamldecode(value).kubeProxy.enabled, true) != false,
          try(yamldecode(value).kubeProxy.service.enabled, true) != false,
          try(yamldecode(value).kubeProxy.serviceMonitor.enabled, true) != false,
          try(yamldecode(value).kubeControllerManager.enabled, true) != false,
          try(yamldecode(value).kubeControllerManager.service.enabled, true) != false,
          try(yamldecode(value).kubeControllerManager.serviceMonitor.enabled, true) != false,
          try(yamldecode(value).kubeScheduler.enabled, true) != false,
          try(yamldecode(value).kubeScheduler.service.enabled, true) != false,
          try(yamldecode(value).kubeScheduler.serviceMonitor.enabled, true) != false,
          try(yamldecode(value).kubeEtcd.enabled, true) != false,
          try(yamldecode(value).kubeEtcd.service.enabled, true) != false,
          try(yamldecode(value).kubeEtcd.serviceMonitor.enabled, true) != false,
        ])
      ]),
      yamldecode(helm_release.prometheus.values[0]).coreDns.serviceMonitor.metricRelabelings[0].regex == "^go_.*",
      yamldecode(helm_release.prometheus.values[0]).kubeProxy.serviceMonitor.metricRelabelings[0].regex == "^go_.*",
      !contains(keys(yamldecode(helm_release.prometheus.values[0])), "kube-state-metrics"),
    ])
    error_message = "The pinned Prometheus chart values must retain all five component monitor paths consumed by the VictoriaMetrics converter without dead bundled KSM values."
  }
}

run "operator_values_are_selector_owned" {
  command = plan

  module {
    source = "../../modules/victoria-metrics"
  }

  variables {
    operator_enabled             = true
    namespace                    = "monitoring"
    release_name                 = "victoria-metrics"
    configs                      = {}
    agent_enabled                = true
    agent_replica_count          = 1
    prometheus_converter_enabled = false
    operator_extra_configs = {
      operator = {
        disable_prometheus_converter = false
        enable_converter_ownership   = true
      }
      watchNamespaces = ["wrong"]
      extraArgs = {
        "controller.disableReconcileFor" = ["PodMonitor", "ServiceMonitor"]
        "loggerLevel"                    = "WARN"
      }
      env = [
        { name = "WATCH_NAMESPACE", value = "dev" },
        {
          name  = "VM_ENABLEDPROMETHEUSCONVERTER_PODMONITOR"
          value = "true"
        },
        { name = "UNRELATED_OPERATOR_ENV", value = "keep" },
      ]
      envFrom = [{ configMapRef = { name = "unsafe-operator-env" } }]
      rbac    = { create = false }
      crds = {
        enabled = false
        plain   = false
        cleanup = { enabled = true }
        upgrade = { enabled = false }
      }
      extraObjects = [{ kind = "WrongObject" }]
    }
  }

  assert {
    condition = alltrue([
      jsondecode(helm_release.victoria_metrics_operator[0].values[1]).operator.disable_prometheus_converter == true,
      jsondecode(helm_release.victoria_metrics_operator[0].values[1]).operator.enable_converter_ownership == false,
      length(jsondecode(helm_release.victoria_metrics_operator[0].values[1]).watchNamespaces) == 0,
      length(jsondecode(helm_release.victoria_metrics_operator[0].values[1]).extraArgs["controller.disableReconcileFor"]) == 0,
      jsondecode(helm_release.victoria_metrics_operator[0].values[1]).extraArgs.loggerLevel == "WARN",
      length([
        for env_var in jsondecode(helm_release.victoria_metrics_operator[0].values[1]).env : env_var
        if try(env_var.name, "") == "WATCH_NAMESPACE" || can(regex(
          "^VM_ENABLEDPROMETHEUSCONVERTER",
          try(env_var.name, ""),
        ))
      ]) == 0,
      contains(
        [for env_var in jsondecode(helm_release.victoria_metrics_operator[0].values[1]).env : env_var.name],
        "UNRELATED_OPERATOR_ENV",
      ),
      length(jsondecode(helm_release.victoria_metrics_operator[0].values[1]).envFrom) == 0,
      jsondecode(helm_release.victoria_metrics_operator[0].values[1]).rbac.create == true,
      jsondecode(helm_release.victoria_metrics_operator[0].values[1]).crds.enabled == true,
      try(jsondecode(helm_release.victoria_metrics_operator[0].values[1]).crds.plain == true, false),
      jsondecode(helm_release.victoria_metrics_operator[0].values[1]).crds.cleanup.enabled == false,
      try(jsondecode(helm_release.victoria_metrics_operator[0].values[1]).crds.upgrade.enabled == true, false),
      length(jsondecode(helm_release.victoria_metrics_operator[0].values[1]).extraObjects) == 0,
      helm_release.victoria_metrics_resources[0].name == "victoria-metrics-operator-resources",
      endswith(helm_release.victoria_metrics_resources[0].chart, "/charts/resources"),
      helm_release.victoria_metrics_resources[0].create_namespace == false,
      one([
        for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : object
        if try(object.kind, "") == "VMAgent"
      ]).metadata.name == "victoria-metrics-agent",
      alltrue([
        for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects :
        object.apiVersion == "operator.victoriametrics.com/v1beta1"
      ]),
    ])
    error_message = "Selector-owned Operator values must close every converter/watch bypass while preserving unrelated explicit settings."
  }
}

run "prometheus_mode_operator_identity_and_storage" {
  command = plan

  module {
    source = "../../modules/victoria-metrics"
  }

  variables {
    operator_enabled = true
    namespace        = "monitoring"
    release_name     = "victoria-metrics"
    configs = {
      retention_period = "30d"
      vmstorage = {
        replica_count = 1
        storage_class = "gp3"
        storage_size  = "100Gi"
        access_modes  = ["ReadWriteOnce"]
      }
    }
    agent_enabled = false
  }

  assert {
    condition = alltrue([
      helm_release.victoria_metrics_operator[0].name == "victoria-metrics-operator",
      helm_release.victoria_metrics_operator[0].chart == "victoria-metrics-operator",
      helm_release.victoria_metrics_operator[0].version == "0.67.2",
      length(jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects) == 0,
      length([
        for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : object
        if try(object.kind, "") == "VMAgent"
      ]) == 0,
      length([
        for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : object
        if try(object.kind, "") == "VMServiceScrape"
      ]) == 0,
      jsondecode(helm_release.victoria_metrics.values[0]).vmstorage.retentionPeriod == "30d",
      jsondecode(helm_release.victoria_metrics.values[0]).vmstorage.replicaCount == 1,
      jsondecode(helm_release.victoria_metrics.values[0]).vmstorage.persistentVolume.storageClassName == "gp3",
      jsondecode(helm_release.victoria_metrics.values[0]).vmstorage.persistentVolume.size == "100Gi",
      jsondecode(helm_release.victoria_metrics.values[0]).vmstorage.persistentVolume.accessModes == ["ReadWriteOnce"],
    ])
    error_message = "Prometheus mode must install the Operator identity while preserving the VictoriaMetrics cluster and storage values without collection objects."
  }
}

run "victoria_mode_monitor_conversion_boundary" {
  command = plan

  module {
    source = "../../modules/victoria-metrics"
  }

  variables {
    operator_enabled    = true
    namespace           = "monitoring"
    release_name        = "victoria-metrics"
    configs             = {}
    agent_enabled       = true
    agent_replica_count = 1
    operator_extra_configs = {
      operator = {
        disable_prometheus_converter = true
        enable_converter_ownership   = false
      }
      watchNamespaces = ["wrong"]
      extraArgs = {
        "controller.disableReconcileFor" = ["PodMonitor", "ServiceMonitor"]
        "loggerLevel"                    = "WARN"
      }
      env = [
        { name = "WATCH_NAMESPACE", value = "dev" },
        {
          name  = "VM_ENABLEDPROMETHEUSCONVERTER_PODMONITOR"
          value = "false"
        },
        { name = "UNRELATED_OPERATOR_ENV", value = "keep" },
      ]
      envFrom = [{ configMapRef = { name = "unsafe-operator-env" } }]
      rbac    = { create = false }
      crds = {
        enabled = false
        cleanup = { enabled = true }
      }
      extraObjects = [{ kind = "WrongObject" }]
    }
    agent_extra_scrape_configs = [{
      job_name     = "application-non-auth"
      metrics_path = "/metrics"
      static_configs = [{
        targets = ["backend.dev.svc.cluster.local:8000"]
        labels  = { credentials = "business-label" }
      }]
    }]
  }

  assert {
    condition = alltrue([
      jsondecode(helm_release.victoria_metrics_operator[0].values[1]).operator.disable_prometheus_converter == false,
      jsondecode(helm_release.victoria_metrics_operator[0].values[1]).operator.enable_converter_ownership == true,
      length(jsondecode(helm_release.victoria_metrics_operator[0].values[1]).watchNamespaces) == 0,
      length(jsondecode(helm_release.victoria_metrics_operator[0].values[1]).extraArgs["controller.disableReconcileFor"]) == 0,
      jsondecode(helm_release.victoria_metrics_operator[0].values[1]).extraArgs.loggerLevel == "WARN",
      length([
        for env_var in jsondecode(helm_release.victoria_metrics_operator[0].values[1]).env : env_var
        if try(env_var.name, "") == "WATCH_NAMESPACE" || can(regex(
          "^VM_ENABLEDPROMETHEUSCONVERTER",
          try(env_var.name, ""),
        ))
      ]) == 0,
      contains(
        [for env_var in jsondecode(helm_release.victoria_metrics_operator[0].values[1]).env : env_var.name],
        "UNRELATED_OPERATOR_ENV",
      ),
      length(jsondecode(helm_release.victoria_metrics_operator[0].values[1]).envFrom) == 0,
      jsondecode(helm_release.victoria_metrics_operator[0].values[1]).rbac.create == true,
      jsondecode(helm_release.victoria_metrics_operator[0].values[1]).crds.enabled == true,
      jsondecode(helm_release.victoria_metrics_operator[0].values[1]).crds.cleanup.enabled == false,
      alltrue([
        for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects :
        try(object.kind, "") != "WrongObject"
      ]),
      one([
        for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : object
        if try(object.kind, "") == "VMAgent"
        ]).spec.inlineScrapeConfig == yamlencode([{
          job_name     = "application-non-auth"
          metrics_path = "/metrics"
          static_configs = [{
            targets = ["backend.dev.svc.cluster.local:8000"]
            labels  = { credentials = "business-label" }
          }]
      }]),
      !contains(keys(yamldecode(one([
        for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : object
        if try(object.kind, "") == "VMAgent"
      ]).spec.inlineScrapeConfig)[0]), "authorization"),
      !contains(keys(yamldecode(one([
        for object in jsondecode(helm_release.victoria_metrics_resources[0].values[0]).objects : object
        if try(object.kind, "") == "VMAgent"
      ]).spec.inlineScrapeConfig)[0]), "bearer_token"),
    ])
    error_message = "The module must preserve exact non-auth inline jobs and must not fabricate application authorization."
  }
}

run "prometheus_scrape_flag_is_selector_owned" {
  command = plan

  module {
    source = "../../modules/prometheus"
  }

  variables {
    collector_enabled = false
    configs           = {}
    extra_configs = {
      crds = {
        enabled = false
      }
      prometheus = {
        enabled = true
      }
      kubelet = {
        serviceMonitor = {
          enabled = true
        }
      }
      nodeExporter = {
        enabled = true
      }
    }
  }

  assert {
    condition     = yamldecode(helm_release.prometheus.values[0]).prometheus.enabled == false
    error_message = "The Prometheus chart template must disable scraping when the selector chooses VictoriaMetrics."
  }

  assert {
    condition     = yamldecode(helm_release.prometheus.values[2]).prometheus.enabled == false
    error_message = "Raw Prometheus extra_configs must not override the selector-owned enabled flag."
  }

  assert {
    condition     = try(yamldecode(helm_release.prometheus.values[0]).kubelet.serviceMonitor.enabled == false, false)
    error_message = "The Prometheus chart template must disable the kubelet ServiceMonitor when the selector chooses VictoriaMetrics."
  }

  assert {
    condition     = try(jsondecode(helm_release.prometheus.values[2]).kubelet.serviceMonitor.enabled == false, false)
    error_message = "Raw Prometheus extra_configs must not override the selector-owned kubelet ServiceMonitor flag."
  }

  assert {
    condition = try(alltrue([
      yamldecode(helm_release.prometheus.values[0]).kubeStateMetrics.enabled == false,
      yamldecode(helm_release.prometheus.values[2]).kubeStateMetrics.enabled == false,
      yamldecode(helm_release.prometheus.values[0]).nodeExporter.enabled == false,
      yamldecode(helm_release.prometheus.values[2]).nodeExporter.enabled == false,
    ]), false)
    error_message = "The Prometheus release must never own either shared exporter."
  }

  assert {
    condition     = try(yamldecode(helm_release.prometheus.values[2]).crds.enabled == true, false)
    error_message = "The Prometheus release must retain ownership of the monitor CRDs required by VictoriaMetrics conversion."
  }
}

run "prometheus_remote_write_preserves_nested_overrides" {
  command = plan

  module {
    source = "../../modules/prometheus"
  }

  variables {
    collector_enabled = true
    configs           = {}
    remote_write_url  = "http://vminsert.monitoring.svc.cluster.local:8480/insert/0/prometheus/api/v1/write"
    extra_configs = {
      prometheus = {
        prometheusSpec = {
          serviceMonitorSelector = {
            matchLabels = {
              team = "platform"
            }
          }
          affinity = {
            podAntiAffinity = {
              preferredDuringSchedulingIgnoredDuringExecution = []
            }
          }
          remoteWrite = [{
            url = "http://caller-owned-destination"
          }]
        }
      }
    }
  }

  assert {
    condition     = try(yamldecode(helm_release.prometheus.values[0]).kubelet.serviceMonitor.enabled == true, false)
    error_message = "The Prometheus chart template must enable the kubelet ServiceMonitor when Prometheus is the collector."
  }

  assert {
    condition     = try(jsondecode(helm_release.prometheus.values[2]).kubelet.serviceMonitor.enabled == true, false)
    error_message = "The selector-owned values layer must enable the kubelet ServiceMonitor when Prometheus is the collector."
  }

  assert {
    condition = try(alltrue([
      jsondecode(helm_release.prometheus.values[1]).prometheus.prometheusSpec.serviceMonitorSelector.matchLabels.team == "platform",
      contains(keys(jsondecode(helm_release.prometheus.values[1]).prometheus.prometheusSpec), "affinity"),
      length(jsondecode(helm_release.prometheus.values[1]).prometheus.prometheusSpec.remoteWrite) == 1,
      jsondecode(helm_release.prometheus.values[1]).prometheus.prometheusSpec.remoteWrite[0].url == "http://vminsert.monitoring.svc.cluster.local:8480/insert/0/prometheus/api/v1/write",
    ]), false)
    error_message = "The selector-owned remoteWrite destination must replace only remoteWrite and retain every other caller prometheusSpec field."
  }
}

run "kube_state_metrics_values_are_collector_owned" {
  command = plan

  module {
    source = "../../modules/kube-state-metrics"
  }

  variables {
    namespace                  = "monitoring"
    release_name               = "kube-state-metrics"
    fullname_override          = "prometheus-kube-state-metrics"
    prometheus_monitor_enabled = true
    prometheus_release_name    = "prometheus"
    extra_configs = {
      fullnameOverride = "wrong-name"
      service = {
        port = 9090
      }
      prometheus = {
        monitor = {
          enabled = false
          additionalLabels = {
            release = "wrong-release"
          }
          http = {
            honorLabels = false
          }
        }
      }
    }
  }

  assert {
    condition = try(alltrue([
      helm_release.kube_state_metrics.name == "kube-state-metrics",
      helm_release.kube_state_metrics.chart == "kube-state-metrics",
      helm_release.kube_state_metrics.version == "7.8.1",
      jsondecode(helm_release.kube_state_metrics.values[1]).fullnameOverride == "prometheus-kube-state-metrics",
      jsondecode(helm_release.kube_state_metrics.values[1]).service.port == 8080,
      jsondecode(helm_release.kube_state_metrics.values[1]).prometheus.monitor.enabled == true,
      jsondecode(helm_release.kube_state_metrics.values[1]).prometheus.monitor.additionalLabels.release == "prometheus",
      jsondecode(helm_release.kube_state_metrics.values[1]).prometheus.monitor.selectorOverride["app.kubernetes.io/name"] == "kube-state-metrics",
      jsondecode(helm_release.kube_state_metrics.values[1]).prometheus.monitor.selectorOverride["app.kubernetes.io/instance"] == "kube-state-metrics",
      jsondecode(helm_release.kube_state_metrics.values[1]).prometheus.monitor.http.honorLabels == true,
      length(try(jsondecode(helm_release.kube_state_metrics.values[1]).prometheus.monitor.http.metricRelabelings, [])) == 1,
      try(jsondecode(helm_release.kube_state_metrics.values[1]).prometheus.monitor.http.metricRelabelings[0].sourceLabels, []) == ["__name__"],
      try(jsondecode(helm_release.kube_state_metrics.values[1]).prometheus.monitor.http.metricRelabelings[0].regex, null) == "^go_.*",
      try(jsondecode(helm_release.kube_state_metrics.values[1]).prometheus.monitor.http.metricRelabelings[0].action, null) == "drop",
      output.service_target == "prometheus-kube-state-metrics.monitoring.svc.cluster.local:8080",
    ]), false)
    error_message = "The standalone release must preserve its Service contract, drop go runtime metrics, and apply collector-owned values last."
  }
}
