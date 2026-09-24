# Data Model: MSK CloudWatch Monitoring

**Feature**: `004-msk-monitoring`

## Entities

### MskDashboardBlockInput

| Field | Type | Description | Validation |
|-------|------|-------------|------------|
| type | string | Block discriminator | Must be `block/msk` |
| block_name | string | Panel section title | Default `"MSK"` |
| cluster_names | list(string) | MSK cluster names (CloudWatch `Cluster Name`) | Required, non-empty |
| region | string | AWS region for CloudWatch queries | Default module cloudwatch region (e.g. `eu-central-1`) |
| period | string | CloudWatch aggregation period | Default `"auto"` |
| datasource_uid | string | Grafana CloudWatch datasource UID | Default `"cloudwatch"` |
| consumer_groups | list(string) | Optional consumer groups for lag panels | Default `[]` |

### MskWidgetConfig

| Field | Type | Description | Validation |
|-------|------|-------------|------------|
| type | string | Widget discriminator | One of `msk/cpu`, `msk/memory`, `msk/throughput_in`, `msk/throughput_out`, `msk/partitions`, `msk/offline_partitions`, `msk/consumer_lag` |
| cluster_names | list(string) | Target clusters | Required |
| region | string | AWS region | Inherited from block |
| period | string | CloudWatch period | Inherited from block |
| datasource_uid | string | CloudWatch datasource UID | Inherited from block |
| consumer_groups | list(string) | Lag dimension filter | Optional |

### MskAlertConfig

| Field | Type | Description | Validation |
|-------|------|-------------|------------|
| enabled | bool | Generate MSK alert rules | Default `false` |
| cluster_names | list(string) | Clusters to monitor | Required when enabled |
| offline_partitions | object | Offline partition alert tuning | `threshold` default `0`, `pending_period` default `5m` |
| cpu | object | Optional high CPU alert | Disabled by default |
| labels | map(any) | Alert routing labels | Default P2/warning |
| annotations | map(string) | Alert message metadata | Optional |
| datasource | string | CloudWatch datasource UID | Default `"cloudwatch"` |
| region | string | AWS region | Required when enabled |

### CloudWatchMetricTarget

| Field | Type | Description |
|-------|------|-------------|
| namespace | string | Always `AWS/Kafka` |
| metric_name | string | CloudWatch metric |
| dimensions | map(string) | `Cluster Name`, optional `Broker ID` or `Consumer Group` |
| statistic | string | Average, Maximum, Sum |
| period | string | Aggregation window |

## Relationships

- Dashboard `rows[]` entry `{ type = "block/msk", ... }` → `module.block_msk` → widget row definitions
- Widget row definitions → `modules/widgets/msk/*` via `widgets-msk.tf` registry
- Optional `block.alerts` merge → `module.block_msk_alerts` → `local.widget_alert_rules` → root alerts module
- Consumer CloudWatch datasource (external) → panels query `AWS/Kafka` metrics

## State Transitions

```text
No MSK block configured
  └─ existing dashboards unchanged

Consumer adds block/msk with cluster_names
  └─ dashboard renders MSK CloudWatch panels

Consumer enables block MSK alerts
  └─ offline partition alert rules appended to alert rule set

Consumer disables MSK alerts
  └─ dashboard panels remain; MSK alert rules omitted
```

## Validation Rules

1. `cluster_names` MUST contain at least one non-empty string when `block/msk` is used.
2. MSK alert rules MUST NOT be generated when `alerts.enabled = false`.
3. Default examples MUST NOT contain client-specific cluster names.
4. RDS block types and widgets MUST remain untouched.
