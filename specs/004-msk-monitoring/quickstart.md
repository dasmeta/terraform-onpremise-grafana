# Quickstart: MSK CloudWatch Monitoring

**Feature**: `004-msk-monitoring`

## Prerequisites

- Grafana with CloudWatch datasource configured (UID typically `cloudwatch`)
- IAM permissions allowing `cloudwatch:GetMetricData` / `GetMetricStatistics` for `AWS/Kafka`
- MSK enhanced monitoring metrics available for target cluster
- Terraform ~> 1.3

## 1. Validate dashboard module example (no AWS apply required)

```sh
cd modules/dashboard/tests/msk-cloudwatch
terraform init
terraform validate
terraform plan
```

**Expected**: Plan succeeds; dashboard module renders MSK block widgets referencing generic cluster `example-msk-cluster`.

## 2. Add MSK block to application dashboard

```hcl
module "grafana_monitoring" {
  source  = "dasmeta/grafana/onpremise"
  version = "<module-version>"

  application_dashboard = [{
    name = "Platform Overview"
    rows = [
      {
        type          = "block/msk"
        block_name    = "Kafka (MSK)"
        cluster_names = ["prod-msk-cluster"]
        region        = "eu-central-1"
        datasource_uid = "cloudwatch"
      }
    ]
  }]
}
```

## 3. Optional consumer lag panels

```hcl
{
  type            = "block/msk"
  cluster_names   = ["prod-msk-cluster"]
  consumer_groups = ["my-service-consumer"]
}
```

## 4. Optional MSK alerting

```hcl
{
  type          = "block/msk"
  cluster_names = ["prod-msk-cluster"]
  alerts = {
    enabled = true
    offline_partitions = {
      threshold      = 0
      pending_period = "5m"
    }
    labels = {
      priority = "P1"
      severity = "critical"
    }
  }
}
```

Apply module — offline partition alert rules are generated when enabled.

## 5. Verify in Grafana (consumer environment)

1. Open the provisioned dashboard.
2. Confirm MSK panels show data for CPU, memory, throughput, partitions.
3. If alerts enabled, confirm offline partition alert appears in Grafana alerting UI.

## Acceptance Evidence

- [x] `terraform validate` passes at repo root
- [x] `terraform validate` passes in `modules/dashboard/tests/msk-cloudwatch/`
- [x] README documents `block/msk` inputs
- [x] Examples use generic cluster names only
- [x] Existing non-MSK dashboards unaffected (opt-in block)
