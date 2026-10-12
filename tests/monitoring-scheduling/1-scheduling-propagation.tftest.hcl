mock_provider "helm" {}
mock_provider "random" {}

run "prometheus_and_alertmanager_scheduling_survives_final_value_composition" {
  command = plan

  module {
    source = "../../modules/prometheus"
  }

  variables {
    collector_enabled = true
    remote_write_url  = "http://vminsert.monitoring.svc.cluster.local:8480/insert/0/prometheus/api/v1/write"
    extra_configs = {
      prometheus = {
        prometheusSpec = {
          nodeSelector = { workload = "monitoring" }
          tolerations  = [{ key = "workload", operator = "Equal", value = "monitoring", effect = "NoSchedule" }]
        }
      }
      alertmanager = {
        alertmanagerSpec = {
          nodeSelector = { workload = "monitoring" }
          tolerations  = [{ key = "workload", operator = "Equal", value = "monitoring", effect = "NoSchedule" }]
        }
      }
      additionalPrometheusRulesMap = {
        generic_rule = {
          groups = [{
            name = "generic"
            rules = [{
              record = "example:metric:sum"
              expr   = "sum(up)"
            }]
          }]
        }
      }
      "kube-state-metrics" = {
        service = {
          annotations = { "prometheus.io/path" = "/metrics" }
        }
      }
      "prometheus-node-exporter" = {
        service = {
          annotations = { "prometheus.io/path" = "/metrics" }
        }
      }
      server = {
        remoteWrite = [{
          queueConfig = {
            capacity          = 500
            maxSamplesPerSend = 250
          }
        }]
      }
    }
  }

  assert {
    condition = try(alltrue([
      length(helm_release.prometheus.values) == 3,
      yamldecode(helm_release.prometheus.values[1]).prometheus.prometheusSpec.nodeSelector.workload == "monitoring",
      yamldecode(helm_release.prometheus.values[1]).prometheus.prometheusSpec.tolerations[0].effect == "NoSchedule",
      yamldecode(helm_release.prometheus.values[1]).alertmanager.alertmanagerSpec.nodeSelector.workload == "monitoring",
      yamldecode(helm_release.prometheus.values[1]).alertmanager.alertmanagerSpec.tolerations[0].effect == "NoSchedule",
      yamldecode(helm_release.prometheus.values[1]).prometheus.prometheusSpec.remoteWrite[0].url == "http://vminsert.monitoring.svc.cluster.local:8480/insert/0/prometheus/api/v1/write",
      yamldecode(helm_release.prometheus.values[2]).prometheus.enabled == true,
    ]), false)
    error_message = "Prometheus and Alertmanager scheduling must survive final Helm value composition without losing remote write."
  }
}

run "victoria_metrics_scheduling_survives_final_value_composition" {
  command = plan

  module {
    source = "../../modules/victoria-metrics"
  }

  variables {
    extra_configs = {
      vminsert = {
        nodeSelector = { workload = "monitoring" }
        tolerations  = [{ key = "workload", operator = "Equal", value = "monitoring", effect = "NoSchedule" }]
      }
      vmselect = {
        nodeSelector = { workload = "monitoring" }
        tolerations  = [{ key = "workload", operator = "Equal", value = "monitoring", effect = "NoSchedule" }]
      }
      vmstorage = {
        nodeSelector = { workload = "monitoring" }
        tolerations  = [{ key = "workload", operator = "Equal", value = "monitoring", effect = "NoSchedule" }]
      }
    }
  }

  assert {
    condition = try(alltrue([
      length(helm_release.victoria_metrics.values) == 3,
      yamldecode(helm_release.victoria_metrics.values[1]).vminsert.nodeSelector.workload == "monitoring",
      yamldecode(helm_release.victoria_metrics.values[1]).vmselect.tolerations[0].effect == "NoSchedule",
      yamldecode(helm_release.victoria_metrics.values[1]).vmstorage.nodeSelector.workload == "monitoring",
      yamldecode(helm_release.victoria_metrics.values[2]).vminsert.service.targetPort == "http",
    ]), false)
    error_message = "VictoriaMetrics scheduling must survive final Helm value composition without losing the endpoint contract."
  }
}

run "tempo_scheduling_survives_final_value_composition" {
  command = plan

  module {
    source = "../../modules/tempo"
  }

  variables {
    configs                      = {}
    metrics_generator_remote_url = "http://vminsert.monitoring.svc.cluster.local:8480/insert/0/prometheus/api/v1/write"
    service_monitor_enabled      = false
    extra_configs = {
      tempo = {
        nodeSelector = { workload = "monitoring" }
        tolerations  = [{ key = "workload", operator = "Equal", value = "monitoring", effect = "NoSchedule" }]
      }
    }
  }

  assert {
    condition = try(alltrue([
      length(helm_release.tempo.values) == 3,
      yamldecode(helm_release.tempo.values[1]).tempo.nodeSelector.workload == "monitoring",
      yamldecode(helm_release.tempo.values[1]).tempo.tolerations[0].effect == "NoSchedule",
      yamldecode(helm_release.tempo.values[2]).tempo.metricsGenerator.remoteWriteUrl == "http://vminsert.monitoring.svc.cluster.local:8480/insert/0/prometheus/api/v1/write",
      yamldecode(helm_release.tempo.values[2]).serviceMonitor.enabled == false,
    ]), false)
    error_message = "Tempo scheduling must survive final Helm value composition without losing module-owned metrics integration."
  }
}

run "loki_scheduling_survives_final_value_composition" {
  command = plan

  module {
    source = "../../modules/loki-stack"
  }

  variables {
    prometheus_monitor_enabled = false
    configs = {
      loki = {
        extra_configs = {
          singleBinary = {
            nodeSelector = { workload = "monitoring" }
            tolerations  = [{ key = "workload", operator = "Equal", value = "monitoring", effect = "NoSchedule" }]
          }
        }
      }
      promtail = { enabled = false }
    }
  }

  assert {
    condition = try(alltrue([
      length(helm_release.loki.values) == 4,
      yamldecode(helm_release.loki.values[2]).singleBinary.nodeSelector.workload == "monitoring",
      yamldecode(helm_release.loki.values[2]).singleBinary.tolerations[0].effect == "NoSchedule",
      yamldecode(helm_release.loki.values[3]).monitoring.serviceMonitor.enabled == false,
    ]), false)
    error_message = "Loki scheduling must survive final Helm value composition without losing module-owned monitoring selection."
  }
}
