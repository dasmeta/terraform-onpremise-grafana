# DMVP-10603 Review: Complete Kafka monitoring

**Ticket:** [DMVP-10603](https://tutorbot.atlassian.net/browse/DMVP-10603)  
**Repo:** `dasmeta/terraform-onpremise-grafana` (`dasmeta/grafana/onpremise`)  
**Branch:** `DMVP-10603-kafka-observability`  
**Status:** Implementation is on the branch. Waiting for reviewer approval before next steps (PR merge, wrapper version bump, consumer enablement).

This document is the review package. Please read it, comment, and approve or request changes.

**Source of the change:** Jira [DMVP-10603](https://tutorbot.atlassian.net/browse/DMVP-10603) (ticket text provided in the implementation request), plus the agreed complete-Kafka scope: CloudWatch MSK **brokers** and Prometheus consumer/Connect observability. Implementation follows existing `block/redis` / `block/rds` / `block/service` patterns in this repo. No live Kafka cluster was available to confirm exporter labels; Prometheus selectors are configurable for that reason.

---

## Grafana blocks you will get

One Grafana dashboard can include **two rows**. Together they are complete Kafka monitoring for this module.

| Grafana section | Row type | Datasource | What you see |
|-----------------|----------|------------|--------------|
| **MSK brokers** | `block/msk` | CloudWatch | Broker CPU, memory, bytes in/out, partition count, offline partitions, CloudWatch consumer lag |
| **Kafka observability** | `block/kafka_observability` | Prometheus | Consumer lag/trend/members, empty groups, Connect REST/state/tasks/totals, exporter health |

```text
Platform Overview dashboard
├── MSK brokers                          CloudWatch  AWS/Kafka
│   ├── CPU Utilisation (%)              per broker
│   ├── Memory Used                      per broker
│   ├── Bytes In                         per cluster
│   ├── Bytes Out                        per cluster
│   ├── Global Partition Count           per cluster
│   ├── Offline Partitions               per cluster
│   └── Consumer Lag                     MaxOffsetLag or EstimatedMaxTimeLag
│
└── Kafka observability                  Prometheus exporters
    ├── Consumer lag                     by consumergroup, topic
    ├── Lag trend                        increase(lag)
    ├── Group members
    ├── Empty consumer groups
    ├── Connect REST up
    ├── Connector state
    ├── Task state
    ├── Connect totals by state
    └── Exporter health (up)
```

Either row can be used alone. Full Kafka coverage uses **both** on the same `application_dashboard`.

---

## 1. Why this exists

Operators need reusable Kafka visibility in Grafana: MSK broker health **and** consumer-group / Kafka Connect behaviour.

Today this module already builds application dashboards from `application_dashboard.rows` (`block/service`, `block/redis`, `block/rds`, …). There was no reusable MSK CloudWatch block and no reusable Prometheus Kafka/Connect block.

This change adds both in the dashboard module so every consumer (including `dasmeta/grafanav12/aws`) can enable them with configuration, not custom panels.

Two datasources are required because the metrics live in different places:

- MSK brokers → CloudWatch namespace `AWS/Kafka`
- Consumer groups / Connect → Prometheus (`kafka_consumergroup_*`, `kafka_connect_*`)

---

## 2. What this is, and what it is not

**This is**

- Two new dashboard row types: `block/msk` and `block/kafka_observability`
- Grafana CloudWatch panels for MSK brokers
- Grafana Prometheus panels for Kafka exporter + Kafka Connect exporter metrics
- Grafana-managed alert rules from the same rows (CloudWatch offline partitions; Prometheus lag/Connect)
- Docs and Terraform validate examples

**This is not**

- A new Grafana installation
- A new Kafka cluster, MSK cluster, or exporter
- Slack / Teams contact points or notification policies
- Secrets, External Secrets, AKHQ, or auto-remediation
- Payconomy (or any customer) environment config
- A required change in `dasmeta/grafanav12/aws` (rows already pass through)
- Speckit / `specs/004-msk-monitoring` (not included)

If a dashboard does not include these row types, behaviour is unchanged.

---

## 3. Where the code lives (why it looks “all dashboard”)

Almost every file is under `modules/dashboard` because that is the only place this repo turns a `rows` entry into Grafana panels and widget alerts.

| Piece | Path | Role |
|-------|------|------|
| MSK block | `modules/dashboard/modules/blocks/msk/` | Expands one row into 7 CloudWatch panels |
| MSK panels | `modules/dashboard/modules/widgets/msk/` | `AWS/Kafka` queries per panel |
| MSK alerts | `modules/dashboard/modules/alerts/block-msk/` | Offline-partitions CloudWatch rule |
| Kafka block | `modules/dashboard/modules/blocks/kafka_observability/` | Expands one row into 9 Prometheus panels |
| Kafka panels | `modules/dashboard/modules/widgets/kafka/` | PromQL for each panel |
| Kafka alerts | `modules/dashboard/modules/alerts/block-kafka-observability/` | Builds Grafana Prometheus alert rules |
| Wiring | `widgets_blocks.tf`, `widgets-msk.tf`, `widgets-kafka.tf`, `locals.tf`, `alerts.tf` | Registers both blocks |
| CloudWatch alert schema | `modules/alerts/modules/rules/` | Optional `cloudwatch_query` on Grafana rules |
| Examples | `modules/dashboard/tests/kafka-observability/`, `modules/dashboard/tests/msk-cloudwatch/` | Combined + MSK-only validate/plan |
| Docs | root `README.md`, `modules/dashboard/README.md` | Consumer usage |

Root `application_dashboard` is already `rows = optional(any, [])`. No new root variable was added.

---

## 3a. What was actually adjusted

This is an **additive** change to the existing dashboard module. We did not rewrite Grafana, alerts routing, or other blocks. We plugged two new row types into the same pipeline used by Redis/RDS/SES.

### Before (unchanged pipeline)

1. Consumer sets `application_dashboard = [{ rows = [ ... ] }]`.
2. Dashboard module scans `rows` for entries whose `type` starts with `block/`.
3. It strips the prefix (`block/rds` → `rds`) and looks up `local.blocks_results["rds"]`.
4. The matching block module returns a list of widget rows.
5. Those widgets are registered by type (`rds/cpu`, `redis/memory`, …) and rendered through `modules/widgets/base`.
6. If alerts are enabled, a block-specific alerts module emits rule objects into `local.widget_alert_rules`, then `modules/alerts/modules/rules` creates Grafana rules.

Unknown `block/*` types are ignored (no panels, no crash). That is why adding Kafka required **registering** both types in those lookup maps.

### After (what we added to that pipeline)

Same steps, plus:

- `block/msk` is a known type → seven `msk/*` widgets
- `block/kafka_observability` is a known type → nine `kafka/*` widgets
- `block_msk_alerts` can emit one CloudWatch offline-partitions rule **when opted in**
- `block_kafka_observability_alerts` can emit 4–5 Prometheus alert rules
- `modules/alerts/modules/rules` accepts `datasource_type = "cloudwatch"` and `cloudwatch_query`

### Existing files we edited (the adjustment)

| File | What we changed | Why |
|------|-----------------|-----|
| `modules/dashboard/widgets_blocks.tf` | Added `module "block_msk"` and `module "block_kafka_observability"` | Same registration as `block_rds` / `block_aws_ses`. Without this, those rows would be skipped. |
| `modules/dashboard/locals.tf` | Added `msk` and `kafka_observability` to `blocks_results`; appended MSK and Kafka widget results to `widget_result` | Block output must be injected back into the row list, and each widget type must be included in the final Grafana panel list. |
| `modules/dashboard/alerts.tf` | Concatenated both alert modules into `widget_alert_rules`; added `_msk` and `_kafka_observability` mergo keys; added the two alerts modules | Same pattern as `block/service`. Dashboard-level `alerts` merge with per-row `alerts`. |
| `modules/dashboard/variables.tf` | Docs only: `alerts` description now mentions `msk` and `kafka_observability` | No type/default change. Existing `alerts` input stays `any`. |
| `modules/alerts/modules/rules/variables.tf` | Optional `cloudwatch_query` object; `datasource_type` may be `cloudwatch` | MSK offline-partitions alerts cannot be Prometheus `expr`. |
| `modules/alerts/modules/rules/main.tf` | CloudWatch Grafana query model when `datasource_type == "cloudwatch"` | Renders `AWS/Kafka` `OfflinePartitionsCount` as a Grafana rule query. |
| `modules/dashboard/README.md` | Combined two-row Kafka example | Reviewers/consumers can copy usage. |
| `README.md` | Same combined example at root | Root README is what AWS-wrapper consumers usually read. |

We did **not** change:

- `application_dashboard` schema (`rows` was already `any`)
- `modules/grafana`, Loki, Prometheus, Tempo, VictoriaMetrics runtime modules
- alert contact points / notification policies
- AWS wrapper repository

Incidental: `modules/loki-stack/README.md` and `modules/victoria-metrics/README.md` may show provider-version table noise from `terraform_docs`. That is not Kafka behaviour.

### New files we added

| Path | What it is |
|------|------------|
| `modules/dashboard/widgets-msk.tf` | Wires seven `msk/*` widget modules from `local.widget_config` |
| `modules/dashboard/widgets-kafka.tf` | Wires nine `kafka/*` widget modules (copy of `widgets-redis.tf` style) |
| `modules/dashboard/modules/blocks/msk/` | MSK block contract + 4 dashboard rows (title + 3 panel rows) |
| `modules/dashboard/modules/blocks/kafka_observability/` | Kafka block contract + 5 dashboard rows (title + 4 panel rows) |
| `modules/dashboard/modules/widgets/msk/<panel>/` | CloudWatch `AWS/Kafka` panels |
| `modules/dashboard/modules/widgets/kafka/<panel>/` | Prometheus panels: `base.tf` PromQL, `locals.tf` selector |
| `modules/dashboard/modules/alerts/block-msk/` | CloudWatch offline-partitions rule |
| `modules/dashboard/modules/alerts/block-kafka-observability/` | Prometheus Grafana rule list |
| `modules/dashboard/tests/msk-cloudwatch/` | MSK-only example |
| `modules/dashboard/tests/kafka-observability/` | Combined MSK + Kafka observability example |
| `docs/DMVP-10603-kafka-observability.md` | This review document |

MSK widget folders (7): `cpu`, `memory`, `throughput_in`, `throughput_out`, `partitions`, `offline_partitions`, `consumer_lag`.

Kafka widget folders (9): `consumer_lag`, `consumer_lag_trend`, `consumer_group_members`, `empty_consumer_groups`, `connect_rest_up`, `connector_state`, `task_state`, `connect_totals`, `exporter_health`.

### Copied pattern (not a new architecture)

| Copied from | Used for |
|-------------|----------|
| `block/rds` / `block/redis` | Block `output.result` is a list of rows of widget objects |
| `widgets-redis.tf` / CloudWatch RDS widgets | One `module` per widget type + `for_each` on `local.widget_config["..."]` |
| `modules/widgets/container/cpu` | Prometheus `expression` panels through `modules/widgets/base` |
| existing CloudWatch widgets | MSK `cloudwatch_targets` through `modules/widgets/base` |
| `modules/alerts/block-service` | Alert objects fed into existing `widget_alerts` |

Difference vs Redis: Redis takes `redis_name`. Kafka observability takes `namespace` plus optional PromQL `extra_filters` / cluster label. MSK takes `cluster_names` (CloudWatch `Cluster Name` dimension) and optional `broker_ids` / `consumer_groups`.

---

## 4. How a consumer enables complete Kafka monitoring

```hcl
application_dashboard = [{
  name = "Platform Overview"
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
      namespace                = "kafka"
      datasource_uid           = "prometheus"
      extra_filters            = "job=~\"kafka-exporter|kafka-connect-exporter\""
      cluster_label            = "cluster"       # optional
      cluster                  = "example-kafka" # optional
      critical_consumer_groups = ["example-payments"]
      idle_consumer_groups     = ["example-idle"]
      stopped_connectors       = ["example-stopped-sink"]
      lag_threshold            = 0
      lag_growth_window        = "15m"
      pending_period           = "5m"
      dashboard_url            = "https://grafana.example.com/d/example-kafka"
      runbook_url              = "https://example.com/runbooks/kafka"
      alerts = {
        enabled         = true
        exporter_scrape = { enabled = true } # optional; default off
      }
    }
  ]
}]
```

Through the AWS wrapper, the same objects go in `application_dashboard` as today. No wrapper input was added.

---

## 5. Configuration contract

### 5.1 `block/msk` (CloudWatch brokers)

| Field | Default | Meaning |
|-------|---------|---------|
| `cluster_names` | required | CloudWatch `Cluster Name` dimension values |
| `broker_ids` | `["1", "2", "3"]` | Broker IDs for CPU/memory series |
| `consumer_groups` | `[]` | If set, lag panel uses `MaxOffsetLag` per group; if empty, `EstimatedMaxTimeLag` per cluster |
| `region` | dashboard CloudWatch region | AWS region |
| `datasource_uid` | `cloudwatch` | Grafana CloudWatch datasource |
| `block_name` | `"MSK"` | Panel section title |
| `alerts.enabled` | **false** (opt-in) | Master switch for MSK alerts |
| `alerts.offline_partitions.threshold` | `0` | Fire when `OfflinePartitionsCount` > threshold |
| `alerts.offline_partitions.pending_period` | `"5m"` | Grafana pending duration |

### 5.2 `block/kafka_observability` (Prometheus consumers / Connect)

**Required**

| Field | Meaning |
|-------|---------|
| `namespace` | Kubernetes namespace used in PromQL `namespace="..."` |

**Optional selectors**

| Field | Default | Meaning |
|-------|---------|---------|
| `datasource_uid` | dashboard Prometheus UID | Grafana Prometheus/VM datasource |
| `extra_filters` | `""` | Extra PromQL matchers, e.g. `job=~"kafka-exporter\|kafka-connect-exporter"` |
| `cluster_label` / `cluster` | empty | Extra matcher only if both are set, e.g. `cluster="example-kafka"` |
| `block_name` | `"Kafka observability"` | Panel section title |

**Lists used by alerts**

| Field | Meaning |
|-------|---------|
| `critical_consumer_groups` | Groups that must stay active. Empty list → lag/empty-member alert is **not** created |
| `idle_consumer_groups` | Excluded from that alert |
| `stopped_connectors` | Excluded from connector/task FAILED alerts |

**Alert tuning**

| Field | Default | Meaning |
|-------|---------|---------|
| `lag_threshold` | `0` | Minimum lag **growth** to fire |
| `lag_growth_window` | `"15m"` | Window in `increase(kafka_consumergroup_lag[window])` |
| `pending_period` | `"5m"` | Grafana pending duration |
| `failed_state` | `"FAILED"` | Connect state label treated as failed |
| `dashboard_url` / `runbook_url` | empty | Optional alert annotations |
| `alerts.enabled` | follows dashboard alerts merge, default on if the block is present and dashboard alerts are on | Master switch |
| `alerts.exporter_scrape.enabled` | `false` | Optional scrape-down alert |
| `alerts.labels` | `priority=P1`, `severity=critical` | Overridable |

No customer-specific names are hardcoded.

---

## 6. Dashboard panels

### 6.1 MSK brokers (`block/msk`)

CloudWatch namespace `AWS/Kafka`. Dimensions: `Cluster Name`, and `Broker ID` where noted.

| Panel | Widget type | Metric |
|-------|-------------|--------|
| CPU Utilisation (%) | `msk/cpu` | `CpuUser` Average + Maximum per broker |
| Memory Used | `msk/memory` | `MemoryUsed` Average per broker |
| Bytes In | `msk/throughput_in` | `BytesInPerSec` Average per cluster |
| Bytes Out | `msk/throughput_out` | `BytesOutPerSec` Average per cluster |
| Global Partition Count | `msk/partitions` | `GlobalPartitionCount` Average per cluster |
| Offline Partitions | `msk/offline_partitions` | `OfflinePartitionsCount` Maximum per cluster |
| Consumer Lag | `msk/consumer_lag` | `MaxOffsetLag` if `consumer_groups` set, else `EstimatedMaxTimeLag` |

Layout from `modules/blocks/msk/output.tf`:

1. Title: `text/title-with-collapse` = `block_name`
2. CPU (8) + memory (8) + bytes in (8)
3. Bytes out (8) + partitions (8) + offline partitions (8)
4. Consumer lag (24)

### 6.2 Kafka observability (`block/kafka_observability`)

All queries are scoped with `namespace`, optional cluster matcher, and `extra_filters`.

| Panel | Widget type | What it queries |
|-------|-------------|-----------------|
| Consumer lag | `kafka/consumer_lag` | `sum by (consumergroup, topic) (kafka_consumergroup_lag)` and `kafka_consumergroup_current_offset_sum` |
| Lag trend | `kafka/consumer_lag_trend` | `sum by (consumergroup) (increase(kafka_consumergroup_lag[period]))` and `kafka_consumergroup_lag_sum` |
| Members | `kafka/consumer_group_members` | `sum by (consumergroup) (kafka_consumergroup_members)` |
| Empty groups | `kafka/empty_consumer_groups` | members `== 0` |
| Connect REST | `kafka/connect_rest_up` | `sum(kafka_connect_rest_up)` (stat) |
| Connector state | `kafka/connector_state` | `sum by (connector, state) (kafka_connect_connector_state)` |
| Task state | `kafka/task_state` | `sum by (connector, task, state) (kafka_connect_task_state)` |
| Totals by state | `kafka/connect_totals` | `kafka_connect_connectors` and `kafka_connect_tasks` by `state` |
| Exporter health | `kafka/exporter_health` | `sum by (job) (up)` (stat) |

Layout from `modules/blocks/kafka_observability/output.tf`:

1. Title: `text/title-with-collapse` = `block_name`
2. Lag (width 12) + lag trend (width 12)
3. Members (12) + empty groups (12)
4. Connect REST (8) + connector state (8) + task state (8)
5. Totals by state (12) + exporter health (12)

Alert lists (`critical_consumer_groups`, idle groups, stopped connectors, thresholds, URLs) are **not** Kafka block-module variables. They stay on the row object and are read by `alerts.tf` via `try(each.value.block.critical_consumer_groups, [])`. The block module only owns panel layout.

### How a PromQL selector is built (every Kafka panel)

Each widget `locals.tf` builds a selector like:

```text
{namespace="kafka",cluster="example-kafka",job=~"kafka-exporter|kafka-connect-exporter"}
```

from:

- `namespace="..."` if namespace is set
- `${cluster_label}="${cluster}"` only if both are set
- raw `extra_filters` string if non-empty

Then metrics look like `kafka_consumergroup_lag${local.selector}`.

Label names can differ by exporter. That is why `extra_filters`, `cluster_label`, and `failed_state` exist.

---

## 7. Alerts

Alerts are Grafana-managed rules, same pipeline as `block/service`. They do **not** create notification policies.

### 7.1 MSK offline partitions (CloudWatch, default off)

Created only when the MSK row sets `alerts.enabled = true` (or dashboard-level alerts `enabled` is true **and** the MSK for_each opt-in matches). Default is **off** so adding broker panels does not start paging.

Query: CloudWatch `AWS/Kafka` / `OfflinePartitionsCount` / dimension `Cluster Name` / statistic `Maximum` / period `300`.  
Fire when value `> 0` (configurable threshold), pending `5m`. Default labels: `priority = P2`, `severity = warning`.

### 7.2 How Kafka observability alerts turn on

```hcl
for_each = {
  for index, item in try(local.blocks_by_type["kafka_observability"], []) :
  index => item
  if try(merge(var.alerts, try(item.block.alerts, {})).enabled, true)
}
```

Meaning:

- Same default as `block/service`: if dashboard alerts are on, adding this block creates Kafka alerts
- Set `alerts = { enabled = false }` on the row to get **panels only**
- Empty `critical_consumer_groups` → skip the “0 members + lag growth” rule only
- `alerts.exporter_scrape.enabled` defaults **false**
- Connector / task / REST rules default **on** when the block’s alerts are on

### 7.3 Critical group: 0 members AND lag growing

Created only when `critical_consumer_groups` is non-empty.

```promql
(
  sum by (consumergroup) (increase(kafka_consumergroup_lag{namespace="...",consumergroup=~"a|b",consumergroup!~"idle"}[15m]))
) > 0
and
(
  sum by (consumergroup) (kafka_consumergroup_members{namespace="...",consumergroup=~"a|b",consumergroup!~"idle"})
) == 0
```

Uses `increase(metric[window])` then `sum by (consumergroup)`, **not** `increase(sum(...)[window])`.  
The firing series keeps `consumergroup` so the group is visible in labels/annotations.

### 7.4 Connector FAILED

```promql
sum by (connector) (kafka_connect_connector_state{namespace="...",state="FAILED",connector!~"stopped"}) > 0
```

### 7.5 Task FAILED

```promql
sum by (connector, task) (kafka_connect_task_state{namespace="...",state="FAILED",connector!~"stopped"}) > 0
```

### 7.6 Connect REST down

```promql
sum(kafka_connect_rest_up{namespace="..."}) == 0
```

### 7.7 Optional exporter scrape failure (default off)

```promql
sum by (job) (up{namespace="...",...}) == 0
```

Each Prometheus rule includes `summary`, `description`, `component`, `metric`, `issue_phrase`, `impact`, and optional `dashboard_url` / `runbook`.

Grafana reduce: `function = last`, `equation = gt`, `threshold = 0` (the PromQL already encodes the condition). `settings_mode = replaceNN` with `0`.

Default labels: `priority = P1`, `severity = critical`. Scrape alert defaults to `P2` / `warning`.

Disable individual Kafka rules with:

```hcl
alerts = {
  enabled = true
  connector_failed    = { enabled = false }
  task_failed         = { enabled = false }
  connect_rest_down   = { enabled = false }
  consumer_group_lag  = { enabled = false }
  exporter_scrape     = { enabled = true }
}
```

---

## 8. Compatibility and wrapper

| Question | Answer |
|----------|--------|
| Breaking change? | No. Additive row types only. CloudWatch `cloudwatch_query` on alert rules is optional and defaults unused |
| Existing dashboards without these blocks? | Unchanged |
| `dasmeta/grafanav12/aws` code change? | **Not required** if it already forwards `application_dashboard` |
| After merge? | Release a new **minor** of `dasmeta/grafana/onpremise`, then bump that version in the AWS wrapper / consumers |
| Duplicate rendering in the wrapper? | Do not. Keep dashboard/alert logic here |

---

## 9. Verification already done

```bash
terraform -chdir=modules/dashboard/tests/kafka-observability init -backend=false
terraform -chdir=modules/dashboard/tests/kafka-observability validate

terraform -chdir=modules/dashboard/tests/msk-cloudwatch init -backend=false
terraform -chdir=modules/dashboard/tests/msk-cloudwatch validate
```

Result: **both configurations are valid**.

Not done in this repo (needs live Grafana + AWS + exporters): apply against a real cluster and confirm CloudWatch dimensions and Prometheus labels (`consumergroup`, `state=FAILED` vs `failed`, etc.).

---

## 10. Reviewer checklist

Please confirm or comment:

- [ ] Grafana will show two sections when both rows are enabled: **MSK brokers** (CloudWatch) and **Kafka observability** (Prometheus)
- [ ] Existing file edits (`widgets_blocks.tf`, `locals.tf`, `alerts.tf`) only register the new types and do not change other blocks
- [ ] Scope is correct: reusable dashboard blocks + Grafana alerts only
- [ ] MSK `cluster_names` / `broker_ids` and Kafka `namespace` / `extra_filters` are generic enough
- [ ] MSK offline-partitions alerts stay **opt-in** (default off)
- [ ] Kafka observability alerts stay service-like (on when dashboard alerts are on; scrape opt-in)
- [ ] Idle groups and stopped connectors are excluded as expected
- [ ] Lag alert PromQL is acceptable (`increase` on lag, then `sum by (consumergroup)`)
- [ ] `cloudwatch_query` on `modules/alerts/modules/rules` is acceptable
- [ ] No Slack/Teams/secrets/customer hardcoding / Speckit files slipped in
- [ ] AWS wrapper does **not** need a forwarding PR unless you know it does not pass `rows`
- [ ] Combined docs/example are enough for a consumer to copy

---

## 11. Approval

**Reviewer:** _______________________  
**Date:** _______________________  

Decision:

- [ ] **Approve** — continue (open/merge PR, then onpremise minor release, then consumer enablement)
- [ ] **Approve with comments** — continue after listed fixes
- [ ] **Request changes** — do not proceed until updated

Comments:

```
(reviewer notes)
```

---

## 12. After approval

1. Open or merge the PR for `DMVP-10603-kafka-observability`
2. Cut a backwards-compatible **minor** of `dasmeta/grafana/onpremise`
3. Point `dasmeta/grafanav12/aws` at that version if it pins this module
4. Enable `block/msk` and `block/kafka_observability` in the target environment config (separate change, not this repo)
