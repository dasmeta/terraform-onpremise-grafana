# Research: MSK CloudWatch Monitoring

**Feature**: `004-msk-monitoring`  
**Date**: 2026-08-07

## Decision 1: CloudWatch namespace and cluster dimension

**Decision**: Use CloudWatch namespace `AWS/Kafka` with primary dimension key `Cluster Name` matching the MSK cluster name configured by consumers.

**Rationale**: AWS documents MSK metrics under `AWS/Kafka`. Cluster-level metrics (throughput, partition counts) use `Cluster Name`. Broker-level metrics add `Broker ID`.

**Alternatives considered**:
- Prometheus JMX exporter metrics — rejected; out of scope and not available in this CloudWatch-focused ticket.
- Custom OpenSearch/Application Signals — rejected; not standard MSK CloudWatch path.

## Decision 2: Widget metric selection

**Decision**: Implement widgets for these CloudWatch metrics:

| Widget | Metric | Statistic | Scope |
|--------|--------|-----------|-------|
| CPU | `CpuUser` (+ optional `CpuSystem`) | Average, Maximum | Per broker, labeled by broker ID |
| Memory | `MemoryUsed` | Average, Maximum | Per broker |
| Throughput In | `BytesInPerSec` | Sum or Average | Cluster |
| Throughput Out | `BytesOutPerSec` | Sum or Average | Cluster |
| Partitions | `GlobalPartitionCount` | Average | Cluster |
| Offline Partitions | `OfflinePartitionsCount` | Maximum | Cluster |
| Consumer Lag | `MaxOffsetLag` | Maximum | Cluster + Consumer Group when provided |

**Rationale**: Covers FR-002 through FR-005 with metrics commonly enabled under MSK enhanced monitoring.

**Alternatives considered**:
- Full broker-level panel for every metric — rejected; cluster-level panels are sufficient for MVP throughput/partition visibility; broker panels reserved for CPU/memory.
- `EstimatedMaxTimeLag` only — rejected; `MaxOffsetLag` is more commonly used for ops triage.

## Decision 3: Dashboard block layout

**Decision**: Model `block/msk` after `block/elasticache_redis` / `block/rds`:

- Row 1 title: collapsible block name
- Row 2: CPU, Memory, Throughput In (width 8 each)
- Row 3: Throughput Out, Partitions, Offline Partitions
- Row 4: Consumer Lag (full width or shared with spare slot)

**Rationale**: Consistent UX with other AWS CloudWatch blocks; satisfies SC-002 four health categories.

**Alternatives considered**:
- Single combined “MSK overview” custom widget — rejected; breaks existing widget registry pattern.

## Decision 4: Multi-cluster support

**Decision**: Accept `cluster_names = list(string)` on `block/msk`; widgets flatten CloudWatch targets per cluster (same pattern as `db_identifiers` / `cache_cluster_ids`).

**Rationale**: FR-006 and SC-003 require multi-cluster support with minimal new abstraction.

## Decision 5: Optional MSK alerting approach

**Decision**: Add `modules/dashboard/modules/alerts/block-msk` that emits alert rule objects for `OfflinePartitionsCount > 0` by default. Extend `modules/alerts/modules/rules` to support `datasource_type = "cloudwatch"` with a CloudWatch metric query model in block A (instead of PromQL `expr`).

**Rationale**: Existing rules module is prometheus/loki only; MSK alerts require CloudWatch query JSON. Extending the shared module avoids duplicate `grafana_rule_group` implementations.

**Alternatives considered**:
- Document manual alert rules only — rejected; spec P2 requires generated offline-partition alerts when enabled.
- Separate `grafana_rule_group` resource in dashboard module — rejected; duplicates labels/annotations/folder wiring in alerts module.

## Decision 6: Consumer lag optional inputs

**Decision**: Add optional `consumer_groups = list(string)` on block/alerts; when empty, lag widget queries cluster-level lag aggregate if available, otherwise panel renders with no-data tolerance.

**Rationale**: Lag metrics require Consumer Group dimension on many MSK setups; optional list avoids hard failure.

## Decision 7: Testing strategy

**Decision**: Add `modules/dashboard/tests/msk-cloudwatch/` with `block/msk` row using generic `cluster_name = "example-msk-cluster"`. Validate with `terraform validate` and plan-only (no live Grafana/AWS).

**Rationale**: Matches `modules/dashboard/tests/aws-cloudwatch/` pattern; no AWS credentials required for validate/plan.

**Alternatives considered**:
- Root-level `tests/msk-cloudwatch/` — rejected; MSK feature is dashboard-submodule scoped like existing CloudWatch block tests.
