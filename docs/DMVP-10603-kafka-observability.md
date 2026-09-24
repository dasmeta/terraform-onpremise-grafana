# Optional Kafka monitoring

Reusable Kafka dashboard and alert blocks in `dasmeta/grafana/onpremise`. Environment files should only pass identifiers, datasource UIDs, thresholds, and `alerts.enabled`. Do not duplicate this implementation in an environment wrapper.

Consumer lag lives on `block/msk` (CloudWatch `MaxOffsetLag`). `block/kafka_observability` is Kafka Connect only.

---

## Architecture

```text
AWS MSK  → CloudWatch DEFAULT AWS/Kafka → Grafana CloudWatch datasource
Kafka Connect in EKS → kafka-connect-status-exporter → Prometheus scrape → VictoriaMetrics → Grafana
Grafana-managed alerts → existing Slack/Teams notification policies
```

No new Slack/Teams contact points are created. Alerts reuse existing labels (`priority`, `severity`, `component`) so current routing still applies.

---

## Grafana blocks you will get

Both rows are optional. Existing dashboards that omit them are unchanged.

| Grafana section | Row type | Datasource | What you see |
|-----------------|----------|------------|--------------|
| **MSK brokers** | `block/msk` | CloudWatch | CPU, memory, data-log disk, bytes in/out, partition count, offline partitions, under-replicated partitions, max/sum consumer lag |
| **Kafka Connect** | `block/kafka_observability` | VictoriaMetrics | REST up, connector state, task state, totals by state, exporter scrape health |

---

## 1. Why this exists

Operators need Kafka visibility without adding more EKS exporters for broker/lag health. DEFAULT CloudWatch MSK metrics cover brokers and lag. Kafka Connect status stays on the existing `kafka-connect-status-exporter`.

---

## 2. What this is, and what it is not

**This is**

- Optional `block/msk` and `block/kafka_observability` rows, disabled until added
- CloudWatch DEFAULT `AWS/Kafka` panels and opt-in Grafana alerts
- VictoriaMetrics panels/alerts for `kafka-connect-status-exporter`
- Docs and validate examples

**This is not**

- Automatic paid MSK enhanced monitoring (`PER_BROKER` / per-topic paid levels)
- A consumer-member-count alert (MSK `ConnectionCount` is a different signal)
- New Slack/Teams contact points or Prometheus/CloudWatch duplicate alarms
- Removal of `kafka-lag-exporter` (follow-up after CloudWatch lag alerts are validated)
- Payconomy or any customer environment config
- Speckit package (explicitly skipped on this branch; merge gates may still require it)

---

## 3. MSK DEFAULT metrics used

Verified against [Amazon MSK CloudWatch DEFAULT metrics](https://docs.aws.amazon.com/msk/latest/developerguide/metrics-details.html). Cluster type assumed: **provisioned Standard brokers**. Express clusters use overlapping DEFAULT names but some disk/lag dimensions differ; set `cluster_names` / `region` per environment after confirming cluster type.

| Panel / alert | Metric | Dimensions | Paid enhanced needed? |
|---------------|--------|------------|------------------------|
| CPU | `CpuUser` | Cluster Name, Broker ID | No |
| Memory | `MemoryUsed` | Cluster Name, Broker ID | No |
| Disk | `KafkaDataLogsDiskUsed` | Cluster Name, Broker ID | No |
| Bytes in/out | `BytesInPerSec` / `BytesOutPerSec` | Cluster Name (existing cluster query) | No |
| Partition count | `GlobalPartitionCount` | Cluster Name | No |
| Offline partitions | `OfflinePartitionsCount` | Cluster Name | No |
| Under-replicated | `UnderReplicatedPartitions` | Cluster Name, Broker ID | No |
| Max / sum lag | `MaxOffsetLag` / `SumOffsetLag` | Cluster Name, Consumer Group, Topic | No |

Lag metrics appear only after a consumer group consumes from a topic, and require ASCII consumer-group names.

### Trade-off

Native MSK lag can detect backlog. It does **not** provide exact per-group active-member count. This module does not alert on broker `ConnectionCount`.

### CloudWatch missing lag data

Lag alerts use Grafana `settings_mode = Strict` and `no_data_state = NoData`. Missing `MaxOffsetLag` is **not** replaced with `0` and is **not** treated as healthy.

---

## 4. kafka-connect-status-exporter metrics

Inspected from the existing exporter script. It reads `GET {CONNECT_URL}/connectors?expand=status` and emits:

| Metric | Labels | Encoding |
|--------|--------|----------|
| `kafka_connect_rest_up` | scrape labels only | `1` REST OK, `0` REST failed |
| `kafka_connect_connector_state` | `connector`, `state` | gauge `1`; `state` is **lowercase** (`running`, `failed`, `paused`, `stopped`, …) |
| `kafka_connect_task_state` | `connector`, `task`, `state` | gauge `1`; lowercase state |
| `kafka_connect_connectors` | `state` | count by lowercase state |
| `kafka_connect_tasks` | `state` | count by lowercase state |

Default failed matcher is `failed`, not `FAILED`. Kubernetes scrape adds `namespace` / `job` / `instance`.

---

## 5. How a consumer enables it

```hcl
application_dashboard = [{
  name = "Platform Overview"
  rows = [
    {
      type            = "block/msk"
      cluster_names   = ["example-msk-cluster"]
      broker_ids      = ["1", "2", "3"]
      consumer_groups = ["example-payments"]
      topics          = ["example-events"]
      lag_threshold   = 10000
      region          = "eu-central-1"
      datasource_uid  = "cloudwatch"
      alerts          = { enabled = true }
    },
    {
      type               = "block/kafka_observability"
      namespace          = "example"
      datasource_uid     = "victoriametrics"
      extra_filters      = "job=~\"example-connect-status-exporter\""
      stopped_connectors = ["example-stopped-sink"]
      alerts             = { enabled = true }
    }
  ]
}]
```

Through `dasmeta/grafanav12/aws`, the same objects go in `application_dashboard`. No wrapper input was added.

Dev YAML example (environment-specific values only):

```yaml
rows:
  - type: block/msk
    cluster_names: ["example-msk-cluster"]
    consumer_groups: ["example-payments"]
    topics: ["example-events"]
    region: eu-central-1
    datasource_uid: cloudwatch
    alerts:
      enabled: true
  - type: block/kafka_observability
    namespace: example
    datasource_uid: victoriametrics
    extra_filters: 'job=~"example-connect-status-exporter"'
    alerts:
      enabled: true
```

Shared-module source: `dasmeta/grafana/onpremise`. The AWS wrapper (`dasmeta/grafanav12/aws`) already forwards `application_dashboard.rows`.

---

## 6. Alerts

All Kafka/MSK widget alerts are **opt-in**. They require `alerts.enabled = true` on that row. Dashboard-level `alerts.enabled` does not turn them on. Grafana owns them. They do not create CloudWatch alarms or Prometheus rules.

| Alert | Source | Default |
|-------|--------|---------|
| Offline partitions `> 0` | CloudWatch `OfflinePartitionsCount` | off until that row sets `alerts.enabled = true` |
| Sustained high lag `MaxOffsetLag > threshold` | CloudWatch, pending `15m` unless `alerts.consumer_lag.pending_period` is set | off; requires `consumer_groups` |
| Connect REST down | `sum(kafka_connect_rest_up) == bool 0`, Grafana `last() > 0` | off until that row sets `alerts.enabled = true` |
| Connector `failed` | `kafka_connect_connector_state{state="failed"}` | off; `stopped_connectors` excluded |
| Task `failed` | `kafka_connect_task_state{state="failed"}` | off; `stopped_connectors` excluded |
| Exporter down or metric missing | `(up == bool 0) or absent(kafka_connect_rest_up)` | off until that row sets `alerts.enabled = true` |

---

## 7. IAM

Reuse the existing Grafana CloudWatch datasource role. If that role cannot read MSK metrics, add:

```text
cloudwatch:GetMetricData
cloudwatch:GetMetricStatistics
cloudwatch:ListMetrics
```

scoped to `AWS/Kafka` in the target account/region. Use the instance/IRSA role already attached to Grafana. Do not add static access keys.

---

## 8. kafka-lag-exporter follow-up

Do **not** remove `kafka-lag-exporter` in this change. After Dev validates CloudWatch `MaxOffsetLag` alerts (growing lag, recovery, NoData on missing metrics), remove the exporter in a separate change.

---

## 9. Verification

```bash
terraform -chdir=modules/dashboard/tests/kafka-observability init -backend=false
terraform -chdir=modules/dashboard/tests/kafka-observability validate
terraform -chdir=modules/dashboard/tests/msk-cloudwatch init -backend=false
terraform -chdir=modules/dashboard/tests/msk-cloudwatch validate
```

Do not apply Terraform or change live infrastructure from this repository.

---

## 10. Controlled Dev test plan

Do this after a consumer enables the two rows in Dev. Do not apply from this module repo.

| Case | Action | Expected |
|------|--------|----------|
| Growing lag | Pause or slow a consumer group so `MaxOffsetLag` stays above threshold for `15m` | CloudWatch lag alert fires; Slack/Teams receive it via existing routing |
| Failed Connect task | Force one task into `failed` | Task-failed Grafana alert fires |
| REST unavailable | Stop Connect REST or point the exporter at a closed port | `kafka_connect_rest_up` is `0`; REST alert fires |
| Exporter failure | Scale the exporter to 0 or break its ServiceMonitor | `up==0` or `kafka_connect_rest_up` absent; exporter alert fires |
| Notification delivery | Confirm the firing alert labels match existing Slack/Teams policies | Message arrives; no new contact point required |
| Recovery | Restore consumer, task, REST, and exporter | Alerts resolve; missing-lag series stay `NoData`, never a silent `0` |

---

## 11. Reviewer checklist

- [ ] Rows are optional and alerts default off
- [ ] Only DEFAULT CloudWatch MSK metrics are used
- [ ] Missing lag uses `Strict` + `NoData`, not `replaceNN=0`
- [ ] No member-count alert from `ConnectionCount`
- [ ] Connect queries match the real exporter (`failed` lowercase)
- [ ] Connect alerts do not expose unused Prometheus lag variables
- [ ] REST-down and exporter-down queries use `== bool 0` so Grafana `last() > 0` can fire
- [ ] MSK/Connect alerts require `alerts.enabled = true` on the row, not dashboard-level enablement
- [ ] MaxOffsetLag pending stays `15m` unless `alerts.consumer_lag.pending_period` is set
- [ ] Empty PromQL matchers do not emit `{,state=...}`
- [ ] `block/kafka_observability` has Connect panels only; Prometheus consumer-lag widgets are not in this PR
- [ ] Slack/Teams routing is reused, not duplicated
- [ ] Environment YAML remains config-only
- [ ] `kafka-lag-exporter` is not removed

---

## 12. After approval

1. Merge `DMVP-10603-kafka-observability`
2. Cut a backwards-compatible **minor** of `dasmeta/grafana/onpremise`
3. Bump that version in `dasmeta/grafanav12/aws` if it pins this module
4. Enable the two rows in Dev YAML only
5. Run the Dev test plan
6. Follow up later to remove `kafka-lag-exporter`
