# MSK Dashboard Block Contract

**Feature**: `004-msk-monitoring`  
**Module**: `modules/dashboard`

## Block Input Contract

Consumers add a dashboard row:

```hcl
{
  type          = "block/msk"
  block_name    = "MSK"
  cluster_names = ["example-msk-cluster"]
  region        = "eu-central-1"       # optional
  period        = "auto"               # optional
  datasource_uid = "cloudwatch"        # optional
  consumer_groups = ["example-group"]  # optional, for lag widget
}
```

## Widget Type Contract

| Widget type | CloudWatch namespace | Metric | Dimensions |
|-------------|---------------------|--------|------------|
| `msk/cpu` | `AWS/Kafka` | `CpuUser` | `Cluster Name`, `Broker ID` |
| `msk/memory` | `AWS/Kafka` | `MemoryUsed` | `Cluster Name`, `Broker ID` |
| `msk/throughput_in` | `AWS/Kafka` | `BytesInPerSec` | `Cluster Name` |
| `msk/throughput_out` | `AWS/Kafka` | `BytesOutPerSec` | `Cluster Name` |
| `msk/partitions` | `AWS/Kafka` | `GlobalPartitionCount` | `Cluster Name` |
| `msk/offline_partitions` | `AWS/Kafka` | `OfflinePartitionsCount` | `Cluster Name` |
| `msk/consumer_lag` | `AWS/Kafka` | `MaxOffsetLag` | `Cluster Name`, `Consumer Group` (when configured) |

## Block Output Layout Contract

`modules/blocks/msk/output.tf` MUST emit three panel rows after the title row:

1. CPU, Memory, Throughput In
2. Throughput Out, Partitions, Offline Partitions
3. Consumer Lag

Each widget entry MUST pass through: `cluster_names`, `region`, `period`, `datasource_uid`, and `consumer_groups` (lag only).

## Registry Contract

`locals.tf` MUST include:

- `blocks_results.msk = values(module.block_msk).*.result`
- Widget panel merge entries for all `msk/*` widget modules in `widgets-msk.tf`

`widgets_blocks.tf` MUST define `module "block_msk"` keyed by `local.blocks_by_type["msk"]`.

## Alert Contract (Optional P2)

When MSK alerts enabled on a block:

```hcl
{
  type = "block/msk"
  cluster_names = ["example-msk-cluster"]
  alerts = {
    enabled = true
    offline_partitions = {
      threshold      = 0
      pending_period = "5m"
    }
  }
}
```

Generated rules MUST include at least one alert where `OfflinePartitionsCount` exceeds threshold for each configured cluster.

Alert rules MUST use CloudWatch datasource type and include route-friendly labels (default P2/warning unless overridden).

## Backward Compatibility Contract

- Dashboards without `block/msk` MUST plan/apply identically to pre-feature behavior.
- Existing `block/rds`, `block/elasticache_redis`, and other blocks MUST remain unchanged.

## Test Verification

`modules/dashboard/tests/msk-cloudwatch/` MUST:

1. Include one `block/msk` row with generic cluster name
2. Pass `terraform validate`
3. Produce a plan that creates dashboard resources without errors
