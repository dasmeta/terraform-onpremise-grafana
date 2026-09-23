module "this" {
  source = "../.."
  name   = "Kafka Observability Dashboard Example"

  folder_name_uids = { "application-dashboard" = "test" }
  data_source      = { uid = "victoriametrics", type = "prometheus" }

  rows = [
    {
      type            = "block/msk"
      block_name      = "MSK brokers"
      cluster_names   = ["example-msk-cluster"]
      broker_ids      = ["1", "2", "3"]
      consumer_groups = ["example-payments"]
      topics          = ["example-events"]
      lag_threshold   = 10000
      region          = "eu-central-1"
      datasource_uid  = "cloudwatch"
      alerts = {
        enabled = true
        offline_partitions = {
          threshold      = 0
          pending_period = "5m"
        }
        consumer_lag = {
          threshold      = 10000
          pending_period = "15m"
        }
      }
    },
    {
      type               = "block/kafka_observability"
      block_name         = "Kafka Connect"
      namespace          = "example"
      datasource_uid     = "victoriametrics"
      extra_filters      = "job=~\"kafka-connect-status-exporter\""
      stopped_connectors = ["example-stopped-sink"]
      pending_period     = "5m"
      dashboard_url      = "https://grafana.example.com/d/example-kafka"
      runbook_url        = "https://example.com/runbooks/kafka"
      alerts = {
        enabled = true
        labels = {
          priority = "P1"
          severity = "critical"
        }
      }
    }
  ]
}
