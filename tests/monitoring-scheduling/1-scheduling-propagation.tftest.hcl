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
    }
  }

  assert {
    condition = try(alltrue([
      length(helm_release.prometheus.values) == 1,
      yamldecode(helm_release.prometheus.values[0]).prometheus.prometheusSpec.nodeSelector.workload == "monitoring",
      yamldecode(helm_release.prometheus.values[0]).prometheus.prometheusSpec.tolerations[0].effect == "NoSchedule",
      yamldecode(helm_release.prometheus.values[0]).alertmanager.alertmanagerSpec.nodeSelector.workload == "monitoring",
      yamldecode(helm_release.prometheus.values[0]).alertmanager.alertmanagerSpec.tolerations[0].effect == "NoSchedule",
      yamldecode(helm_release.prometheus.values[0]).prometheus.prometheusSpec.remoteWrite[0].url == "http://vminsert.monitoring.svc.cluster.local:8480/insert/0/prometheus/api/v1/write",
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
      length(helm_release.victoria_metrics.values) == 1,
      yamldecode(helm_release.victoria_metrics.values[0]).vminsert.nodeSelector.workload == "monitoring",
      yamldecode(helm_release.victoria_metrics.values[0]).vmselect.tolerations[0].effect == "NoSchedule",
      yamldecode(helm_release.victoria_metrics.values[0]).vmstorage.nodeSelector.workload == "monitoring",
      yamldecode(helm_release.victoria_metrics.values[0]).vminsert.service.targetPort == "http",
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
      length(helm_release.tempo.values) == 1,
      yamldecode(helm_release.tempo.values[0]).tempo.nodeSelector.workload == "monitoring",
      yamldecode(helm_release.tempo.values[0]).tempo.tolerations[0].effect == "NoSchedule",
      yamldecode(helm_release.tempo.values[0]).tempo.metricsGenerator.remoteWriteUrl == "http://vminsert.monitoring.svc.cluster.local:8480/insert/0/prometheus/api/v1/write",
      yamldecode(helm_release.tempo.values[0]).serviceMonitor.enabled == false,
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
      length(helm_release.loki.values) == 1,
      yamldecode(helm_release.loki.values[0]).singleBinary.nodeSelector.workload == "monitoring",
      yamldecode(helm_release.loki.values[0]).singleBinary.tolerations[0].effect == "NoSchedule",
      yamldecode(helm_release.loki.values[0]).monitoring.serviceMonitor.enabled == false,
    ]), false)
    error_message = "Loki scheduling must survive final Helm value composition without losing module-owned monitoring selection."
  }
}
