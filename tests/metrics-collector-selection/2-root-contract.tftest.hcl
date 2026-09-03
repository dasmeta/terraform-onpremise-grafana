mock_provider "helm" {}
mock_provider "grafana" {}

run "prometheus_only_remains_supported" {
  command = plan

  module {
    source = "../.."
  }

  variables {
    metrics_collector = "prometheus"
    grafana = {
      enabled = false
    }
    prometheus = {
      enabled = true
    }
    victoria_metrics = {
      enabled = false
    }
    tempo = {
      enabled = false
    }
    loki_stack = {
      enabled = false
    }
    alerts = {
      disk_capacity = {
        enabled = false
      }
      rules          = []
      contact_points = null
      notifications  = null
    }
  }

  assert {
    condition = alltrue([
      output.metrics_collector_status.prometheus_installed,
      !output.metrics_collector_status.victoria_metrics_installed,
      output.metrics_collector_status.prometheus_scraping_enabled,
      !output.metrics_collector_status.victoria_metrics_agent_enabled,
      !output.metrics_collector_status.prometheus_remote_write_enabled,
      output.metrics_collector_status.default_datasource_uid == "prometheus",
      output.metrics_collector_status.kube_state_metrics_installed,
      output.metrics_collector_status.kube_state_metrics_prometheus_monitor_enabled,
      !output.metrics_collector_status.kube_state_metrics_vm_service_scrape_enabled,
      output.metrics_collector_status.node_exporter_installed,
      output.metrics_collector_status.node_exporter_prometheus_monitor_enabled,
      !output.metrics_collector_status.node_exporter_vm_service_scrape_enabled,
    ])
    error_message = "Prometheus-only configurations must remain valid without VictoriaMetrics."
  }
}

run "victoria_metrics_only_is_supported" {
  command = plan

  module {
    source = "../.."
  }

  variables {
    metrics_collector = "victoria_metrics"
    grafana           = { enabled = false }
    prometheus        = { enabled = false }
    victoria_metrics  = { enabled = true }
    tempo             = { enabled = false }
    loki_stack        = { enabled = false }
    alerts = {
      disk_capacity  = { enabled = false }
      rules          = []
      contact_points = null
      notifications  = null
    }
  }

  assert {
    condition = alltrue([
      output.metrics_collector_status.active == "victoria_metrics",
      !output.metrics_collector_status.prometheus_installed,
      output.metrics_collector_status.victoria_metrics_installed,
      !output.metrics_collector_status.prometheus_scraping_enabled,
      output.metrics_collector_status.victoria_metrics_agent_enabled,
      output.metrics_collector_status.victoria_metrics_standalone,
      !output.metrics_collector_status.prometheus_converter_enabled,
      output.metrics_collector_status.default_datasource_uid == "victoriametrics",
      output.metrics_collector_status.kube_state_metrics_installed,
      !output.metrics_collector_status.kube_state_metrics_prometheus_monitor_enabled,
      output.metrics_collector_status.kube_state_metrics_vm_service_scrape_enabled,
      output.metrics_collector_status.node_exporter_installed,
      !output.metrics_collector_status.node_exporter_prometheus_monitor_enabled,
      output.metrics_collector_status.node_exporter_vm_service_scrape_enabled,
      output.metrics_collector_status.vm_node_scrapes.kubelet,
      output.metrics_collector_status.vm_node_scrapes.cadvisor,
      !output.metrics_collector_status.vm_node_scrapes.resource,
    ])
    error_message = "VictoriaMetrics-only must be valid without Prometheus or its monitor CRDs."
  }
}

run "invalid_selector" {
  command = plan

  module {
    source = "../.."
  }

  variables {
    metrics_collector      = "telegraf"
    grafana_admin_password = "test-password"
    grafana = {
      enabled = false
    }
    prometheus = {
      enabled = true
    }
    victoria_metrics = {
      enabled = true
    }
    tempo = {
      enabled = false
    }
    loki_stack = {
      enabled = false
    }
    alerts = {
      disk_capacity = {
        enabled = false
      }
      rules          = []
      contact_points = null
      notifications  = null
    }
  }

  expect_failures = [var.metrics_collector]
}

run "selected_backend_must_be_installed" {
  command = plan

  module {
    source = "../.."
  }

  variables {
    metrics_collector      = "victoria_metrics"
    grafana_admin_password = "test-password"
    grafana = {
      enabled = false
    }
    prometheus = {
      enabled = true
    }
    victoria_metrics = {
      enabled = false
    }
    tempo = {
      enabled = false
    }
    loki_stack = {
      enabled = false
    }
    alerts = {
      disk_capacity = {
        enabled = false
      }
      rules          = []
      contact_points = null
      notifications  = null
    }
  }

  expect_failures = [output.metrics_collector]
}

run "invalid_vmagent_name_uppercase" {
  command = plan

  module {
    source = "../.."
  }

  variables {
    metrics_collector = "victoria_metrics"
    prometheus = {
      enabled = true
    }
    victoria_metrics = {
      enabled = true
      agent = {
        name = "Invalid_Name"
      }
    }
    grafana = {
      enabled = false
    }
    tempo = {
      enabled = false
    }
    loki_stack = {
      enabled = false
    }
    alerts = {
      disk_capacity = {
        enabled = false
      }
      rules          = []
      contact_points = null
      notifications  = null
    }
  }

  expect_failures = [var.victoria_metrics]
}

run "invalid_vmagent_name_empty_label" {
  command = plan

  module {
    source = "../.."
  }

  variables {
    metrics_collector = "victoria_metrics"
    prometheus = {
      enabled = true
    }
    victoria_metrics = {
      enabled = true
      agent = {
        name = "a..b"
      }
    }
    grafana = {
      enabled = false
    }
    tempo = {
      enabled = false
    }
    loki_stack = {
      enabled = false
    }
    alerts = {
      disk_capacity = {
        enabled = false
      }
      rules          = []
      contact_points = null
      notifications  = null
    }
  }

  expect_failures = [var.victoria_metrics]
}

run "invalid_vmagent_name_label_starts_with_hyphen" {
  command = plan

  module {
    source = "../.."
  }

  variables {
    metrics_collector = "victoria_metrics"
    prometheus = {
      enabled = true
    }
    victoria_metrics = {
      enabled = true
      agent = {
        name = "a.-b"
      }
    }
    grafana = {
      enabled = false
    }
    tempo = {
      enabled = false
    }
    loki_stack = {
      enabled = false
    }
    alerts = {
      disk_capacity = {
        enabled = false
      }
      rules          = []
      contact_points = null
      notifications  = null
    }
  }

  expect_failures = [var.victoria_metrics]
}

run "invalid_vmagent_replica_count_zero" {
  command = plan

  module {
    source = "../.."
  }

  variables {
    metrics_collector = "victoria_metrics"
    prometheus = {
      enabled = true
    }
    victoria_metrics = {
      enabled = true
      agent = {
        replica_count = 0
      }
    }
    grafana = {
      enabled = false
    }
    tempo = {
      enabled = false
    }
    loki_stack = {
      enabled = false
    }
    alerts = {
      disk_capacity = {
        enabled = false
      }
      rules          = []
      contact_points = null
      notifications  = null
    }
  }

  expect_failures = [var.victoria_metrics]
}

run "invalid_vmagent_replica_count_negative" {
  command = plan

  module {
    source = "../.."
  }

  variables {
    metrics_collector = "victoria_metrics"
    prometheus = {
      enabled = true
    }
    victoria_metrics = {
      enabled = true
      agent = {
        replica_count = -1
      }
    }
    grafana = {
      enabled = false
    }
    tempo = {
      enabled = false
    }
    loki_stack = {
      enabled = false
    }
    alerts = {
      disk_capacity = {
        enabled = false
      }
      rules          = []
      contact_points = null
      notifications  = null
    }
  }

  expect_failures = [var.victoria_metrics]
}

run "invalid_vmagent_replica_count_fractional" {
  command = plan

  module {
    source = "../.."
  }

  variables {
    metrics_collector = "victoria_metrics"
    prometheus = {
      enabled = true
    }
    victoria_metrics = {
      enabled = true
      agent = {
        replica_count = 1.5
      }
    }
    grafana = {
      enabled = false
    }
    tempo = {
      enabled = false
    }
    loki_stack = {
      enabled = false
    }
    alerts = {
      disk_capacity = {
        enabled = false
      }
      rules          = []
      contact_points = null
      notifications  = null
    }
  }

  expect_failures = [var.victoria_metrics]
}

run "prometheus_first_dual_backend" {
  command = apply

  module {
    source = "../.."
  }

  variables {
    metrics_collector      = "prometheus"
    grafana_admin_password = "test-password"
    grafana = {
      enabled = true
    }
    prometheus = {
      enabled = true
    }
    victoria_metrics = {
      enabled = true
    }
    tempo = {
      enabled = false
    }
    loki_stack = {
      enabled = false
    }
    alerts = {
      disk_capacity = {
        enabled = false
      }
      rules          = []
      contact_points = null
      notifications  = null
    }
  }

  assert {
    condition     = output.metrics_collector == "prometheus"
    error_message = "Prometheus-first mode must expose prometheus as the selected collector."
  }

  assert {
    condition = alltrue([
      output.metrics_collector_status.prometheus_installed,
      output.metrics_collector_status.victoria_metrics_installed,
      output.metrics_collector_status.victoria_metrics_operator_installed,
      output.metrics_collector_status.prometheus_scraping_enabled,
      !output.metrics_collector_status.victoria_metrics_agent_enabled,
      output.metrics_collector_status.victoria_metrics_agent_name == null,
      output.metrics_collector_status.prometheus_remote_write_enabled,
      output.metrics_collector_status.default_datasource_uid == "prometheus",
    ])
    error_message = "Prometheus-first mode must activate Prometheus, keep the Operator installed, and leave VMAgent disabled."
  }

  assert {
    condition = alltrue([
      contains(keys(output.grafana.datasources), "Prometheus"),
      contains(keys(output.grafana.datasources), "VictoriaMetrics"),
      output.grafana.datasources["Prometheus"].uid == "prometheus",
      output.grafana.datasources["VictoriaMetrics"].uid == "victoriametrics",
      tobool(output.grafana.datasources["Prometheus"].is_default) == true,
      tobool(output.grafana.datasources["VictoriaMetrics"].is_default) == false,
      length([
        for datasource in values(output.grafana.datasources) : datasource
        if try(tobool(datasource.is_default), false)
      ]) == 1,
    ])
    error_message = "Both metrics datasources must be provisioned and only Prometheus may be default in Prometheus mode."
  }

  assert {
    condition = try(alltrue([
      output.metrics_collector_status.kube_state_metrics_installed,
      output.metrics_collector_status.kube_state_metrics_prometheus_monitor_enabled,
      !output.metrics_collector_status.kube_state_metrics_vm_service_scrape_enabled,
      output.metrics_collector_status.kube_state_metrics_chart_version == "6.1.0",
      output.metrics_collector_status.kube_state_metrics_service_target == "prometheus-kube-state-metrics.monitoring.svc.cluster.local:8080",
    ]), false)
    error_message = "Prometheus mode must keep the independent exporter and enable its ServiceMonitor."
  }
}

run "victoria_metrics_active" {
  command = apply

  module {
    source = "../.."
  }

  variables {
    metrics_collector      = "victoria_metrics"
    grafana_admin_password = "test-password"
    grafana = {
      enabled = true
    }
    prometheus = {
      enabled = true
    }
    victoria_metrics = {
      enabled = true
    }
    tempo = {
      enabled = false
    }
    loki_stack = {
      enabled = false
    }
    alerts = {
      disk_capacity = {
        enabled = false
      }
      rules          = []
      contact_points = null
      notifications  = null
    }
  }

  assert {
    condition = alltrue([
      output.metrics_collector_status.prometheus_installed,
      output.metrics_collector_status.victoria_metrics_installed,
      output.metrics_collector_status.victoria_metrics_operator_installed,
      output.metrics_collector_status.victoria_metrics_agent_enabled,
      output.metrics_collector_status.victoria_metrics_agent_name == "victoria-metrics-agent",
      output.metrics_collector_status.victoria_metrics_remote_write_url == "http://victoria-metrics-victoria-metrics-cluster-vminsert.monitoring.svc.cluster.local:8480/insert/0/prometheus/api/v1/write",
      output.metrics_collector_status.kube_state_metrics_vm_service_scrape_enabled,
      !output.metrics_collector_status.prometheus_scraping_enabled,
      !output.metrics_collector_status.prometheus_remote_write_enabled,
      output.metrics_collector_status.default_datasource_uid == "victoriametrics",
    ])
    error_message = "VictoriaMetrics mode must activate the Operator-managed VMAgent and native KSM path while disabling Prometheus scraping."
  }

  assert {
    condition = alltrue([
      contains(keys(output.grafana.datasources), "Prometheus"),
      contains(keys(output.grafana.datasources), "VictoriaMetrics"),
      output.grafana.datasources["Prometheus"].uid == "prometheus",
      output.grafana.datasources["VictoriaMetrics"].uid == "victoriametrics",
      output.grafana.datasources["VictoriaMetrics"].url == "http://victoria-metrics-victoria-metrics-cluster-vmselect.monitoring.svc.cluster.local:8481/select/0/prometheus",
      tobool(output.grafana.datasources["Prometheus"].is_default) == false,
      tobool(output.grafana.datasources["VictoriaMetrics"].is_default) == true,
      length([
        for datasource in values(output.grafana.datasources) : datasource
        if try(tobool(datasource.is_default), false)
      ]) == 1,
      output.metrics_collector_status.default_datasource_uid == "victoriametrics",
    ])
    error_message = "Both metrics datasources must remain provisioned and only VictoriaMetrics may be default in Victoria mode."
  }
}
