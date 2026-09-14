module "this" {
  source = "../.."

  metrics_collector = var.metrics_collector

  grafana = {
    enabled = false
  }

  prometheus = {
    enabled = var.prometheus_enabled
  }

  node_exporter = {
    enabled = var.node_exporter_enabled
  }

  victoria_metrics = {
    enabled = var.victoria_metrics_enabled

    operator = {
      enabled       = var.operator_enabled
      chart_version = var.operator_chart_version
      release_name  = var.operator_release_name
      extra_configs = {}
    }

    agent = {
      name                    = var.agent_name
      replica_count           = var.agent_replica_count
      kubelet_scrape_enabled  = var.agent_kubelet_scrape_enabled
      cadvisor_scrape_enabled = var.agent_cadvisor_scrape_enabled
      resource_scrape_enabled = var.agent_resource_scrape_enabled
      extra_scrape_configs    = []
      extra_configs           = {}
    }
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

output "metrics_collector" {
  value = module.this.metrics_collector
}

output "metrics_collector_status" {
  value = module.this.metrics_collector_status
}
