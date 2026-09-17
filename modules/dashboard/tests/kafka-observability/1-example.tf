module "this" {
  source = "../.."
  name   = "Kafka Observability Dashboard Example"

  folder_name_uids = { "application-dashboard" = "test" }
  data_source      = { uid = "prometheus", type = "prometheus" }

  rows = [
    {
      type           = "block/msk"
      block_name     = "MSK brokers"
      cluster_names  = ["example-msk-cluster"]
      broker_ids     = ["1", "2", "3"]
      region         = "eu-central-1"
      datasource_uid = "cloudwatch"
      alerts = {
        enabled = true
        offline_partitions = {
          threshold      = 0
          pending_period = "5m"
        }
      }
    },
    {
      type                     = "block/kafka_observability"
      block_name               = "Kafka observability"
      namespace                = "kafka"
      datasource_uid           = "prometheus"
      extra_filters            = "job=~\"kafka-exporter|kafka-connect-exporter\""
      cluster_label            = "cluster"
      cluster                  = "example-kafka"
      critical_consumer_groups = ["example-payments", "example-ledger"]
      idle_consumer_groups     = ["example-idle"]
      stopped_connectors       = ["example-stopped-sink"]
      lag_threshold            = 0
      lag_growth_window        = "15m"
      pending_period           = "5m"
      dashboard_url            = "https://grafana.example.com/d/example-kafka"
      runbook_url              = "https://example.com/runbooks/kafka"
      alerts = {
        enabled = true
        exporter_scrape = {
          enabled = true
        }
        labels = {
          priority = "P1"
          severity = "critical"
        }
      }
    },
    {
      name      = "example-service"
      namespace = "default"
      type      = "block/service"
    }
  ]
}
