# DMVP-10603 Review: Kafka observability block

**Ticket:** [DMVP-10603](https://tutorbot.atlassian.net/browse/DMVP-10603)  
**Repo:** `dasmeta/terraform-onpremise-grafana` (`dasmeta/grafana/onpremise`)  
**Branch:** `DMVP-10603-kafka-observability`  
**Status:** Implementation is on the branch. Waiting for reviewer approval before next steps (PR merge, wrapper version bump, consumer enablement).

This document is the review package. Please read it, comment, and approve or request changes.

---

## 1. Why this exists

Operators need reusable Kafka consumer-group and Kafka Connect visibility in Grafana.

Today this module already builds application dashboards from `application_dashboard.rows` blocks (`block/service`, `block/redis`, `block/rds`, …). There was no reusable Prometheus Kafka/Connect block.

This change adds that block in the dashboard module so every consumer (including `dasmeta/grafanav12/aws`) can enable it with configuration, not custom panels.

---

## 2. What this is, and what it is not

**This is**

- One new dashboard row type: `type = "block/kafka_observability"`
- Grafana panels for Kafka exporter + Kafka Connect exporter metrics
- Grafana-managed Prometheus alert rules generated from the same row
- Docs and a Terraform validate example

**This is not**

- A new Grafana installation
- A new Kafka cluster or exporter
- CloudWatch / `block/msk` (different feature)
- Slack / Teams contact points or notification policies
- Secrets, External Secrets, AKHQ, or auto-remediation
- Payconomy (or any customer) environment config
- A required change in `dasmeta/grafanav12/aws` (rows already pass through)

If a dashboard does not include this row type, behaviour is unchanged.

---

## 3. Where the code lives (why it looks “all dashboard”)

Almost every file is under `modules/dashboard` because that is the only place this repo turns a `rows` entry into Grafana panels and widget alerts.

| Piece | Path | Role |
|-------|------|------|
| Block | `modules/dashboard/modules/blocks/kafka_observability/` | Expands one row into 9 panels |
| Panels | `modules/dashboard/modules/widgets/kafka/` | PromQL for each panel |
| Alerts | `modules/dashboard/modules/alerts/block-kafka-observability/` | Builds Grafana alert rules |
| Wiring | `widgets_blocks.tf`, `widgets-kafka.tf`, `locals.tf`, `alerts.tf` | Registers the new block |
| Example | `modules/dashboard/tests/kafka-observability/` | Validate/plan example |
| Docs | root `README.md`, `modules/dashboard/README.md` | Consumer usage |

Root `application_dashboard` is already `rows = optional(any, [])`. No new root variable was added.

---

## 4. How a consumer enables it

```hcl
application_dashboard = [{
  name = "Platform Overview"
  rows = [
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

Through the AWS wrapper, the same object goes in `application_dashboard` as today. No wrapper input was added.

---

## 5. Configuration contract

### Required

| Field | Meaning |
|-------|---------|
| `namespace` | Kubernetes namespace used in PromQL `namespace="..."` |

### Optional selectors

| Field | Default | Meaning |
|-------|---------|---------|
| `datasource_uid` | dashboard Prometheus UID | Grafana Prometheus/VM datasource |
| `extra_filters` | `""` | Extra PromQL matchers, e.g. `job=~"kafka-exporter\|kafka-connect-exporter"` |
| `cluster_label` / `cluster` | empty | Extra matcher only if both are set, e.g. `cluster="example-kafka"` |
| `block_name` | `"Kafka observability"` | Panel section title |

### Lists used by alerts

| Field | Meaning |
|-------|---------|
| `critical_consumer_groups` | Groups that must stay active. Empty list → lag/empty-member alert is **not** created |
| `idle_consumer_groups` | Excluded from that alert |
| `stopped_connectors` | Excluded from connector/task FAILED alerts |

### Alert tuning

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

Metrics named in the ticket and used:

- Consumer: `kafka_consumergroup_lag`, `kafka_consumergroup_lag_sum`, `kafka_consumergroup_members`, `kafka_consumergroup_current_offset_sum` (per-partition `kafka_consumergroup_current_offset` is not charted; it is high-cardinality)
- Connect: `kafka_connect_rest_up`, `kafka_connect_connector_state`, `kafka_connect_task_state`, `kafka_connect_connectors`, `kafka_connect_tasks`

Label names can differ by exporter. That is why `extra_filters`, `cluster_label`, and `failed_state` exist.

---

## 7. Alerts (concrete PromQL)

Alerts are Grafana-managed rules, same pipeline as `block/service`. They do **not** create notification policies.

### 7.1 Critical group: 0 members AND lag growing

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

### 7.2 Connector FAILED

```promql
sum by (connector) (kafka_connect_connector_state{namespace="...",state="FAILED",connector!~"stopped"}) > 0
```

### 7.3 Task FAILED

```promql
sum by (connector, task) (kafka_connect_task_state{namespace="...",state="FAILED",connector!~"stopped"}) > 0
```

### 7.4 Connect REST down

```promql
sum(kafka_connect_rest_up{namespace="..."}) == 0
```

### 7.5 Optional exporter scrape failure (default off)

```promql
sum by (job) (up{namespace="...",...}) == 0
```

Each rule includes `summary`, `description`, and optional `dashboard_url` / `runbook`.

---

## 8. Compatibility and wrapper

| Question | Answer |
|----------|--------|
| Breaking change? | No. Additive row type only |
| Existing dashboards without this block? | Unchanged |
| `dasmeta/grafanav12/aws` code change? | **Not required** if it already forwards `application_dashboard` |
| After merge? | Release a new **minor** of `dasmeta/grafana/onpremise`, then bump that version in the AWS wrapper / consumers |
| Duplicate rendering in the wrapper? | Do not. Keep dashboard/alert logic here |

---

## 9. Verification already done

```bash
terraform -chdir=modules/dashboard/tests/kafka-observability init -backend=false
terraform -chdir=modules/dashboard/tests/kafka-observability validate
```

Result: **valid**.

Not done in this repo (needs a live Grafana + exporters): apply against a real cluster and confirm metric labels (`consumergroup`, `state=FAILED` vs `failed`, etc.).

---

## 10. Reviewer checklist

Please confirm or comment:

- [ ] Scope is correct: reusable dashboard block + Grafana alerts only
- [ ] Row type `block/kafka_observability` is the right consumer interface
- [ ] Selectors are generic enough (`namespace`, `extra_filters`, optional cluster)
- [ ] Idle groups and stopped connectors are excluded as expected
- [ ] Lag alert PromQL is acceptable (`increase` on lag, then `sum by (consumergroup)`)
- [ ] No Slack/Teams/secrets/customer hardcoding slipped in
- [ ] AWS wrapper does **not** need a forwarding PR unless you know it does not pass `rows`
- [ ] Docs/example are enough for a consumer to copy

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
4. Enable `block/kafka_observability` in the target environment config (separate change, not this repo)
