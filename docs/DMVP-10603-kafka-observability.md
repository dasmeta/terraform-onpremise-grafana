# DMVP-10603 Review: Kafka observability block

**Ticket:** [DMVP-10603](https://tutorbot.atlassian.net/browse/DMVP-10603)  
**Repo:** `dasmeta/terraform-onpremise-grafana` (`dasmeta/grafana/onpremise`)  
**Branch:** `DMVP-10603-kafka-observability`  
**Status:** Implementation is on the branch. Waiting for reviewer approval before next steps (PR merge, wrapper version bump, consumer enablement).

This document is the review package. Please read it, comment, and approve or request changes.

**Source of the change:** Jira [DMVP-10603](https://tutorbot.atlassian.net/browse/DMVP-10603) (ticket text provided in the implementation request). Implementation follows existing `block/redis` / `block/rds` / `block/service` patterns in this repo. No live Kafka cluster was available to confirm exporter labels; selectors are configurable for that reason.

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

## 3a. What was actually adjusted

This is an **additive** change to the existing dashboard module. We did not rewrite Grafana, alerts routing, or other blocks. We plugged a new row type into the same pipeline used by Redis/RDS/SES.

### Before (unchanged pipeline)

1. Consumer sets `application_dashboard = [{ rows = [ ... ] }]`.
2. Dashboard module scans `rows` for entries whose `type` starts with `block/`.
3. It strips the prefix (`block/rds` → `rds`) and looks up `local.blocks_results["rds"]`.
4. The matching block module returns a list of widget rows.
5. Those widgets are registered by type (`rds/cpu`, `redis/memory`, …) and rendered through `modules/widgets/base`.
6. If alerts are enabled, a block-specific alerts module emits rule objects into `local.widget_alert_rules`, then `modules/alerts/modules/rules` creates Grafana rules.

Unknown `block/*` types are ignored (no panels, no crash). That is why adding Kafka required **registering** it in those lookup maps.

### After (what we added to that pipeline)

Same steps, plus:

- `block/kafka_observability` is a known type
- it expands to nine `kafka/*` widgets
- `block_kafka_observability_alerts` can emit 4–5 Prometheus alert rules

### Existing files we edited (the adjustment)

These are the only **existing** Terraform files that changed. Everything else is new files.

| File | What we changed | Why |
|------|-----------------|-----|
| `modules/dashboard/widgets_blocks.tf` | Added `module "block_kafka_observability"` `for_each` over `local.blocks_by_type["kafka_observability"]` | Same registration as `block_rds` / `block_aws_ses`. Without this, a Kafka row would be skipped. |
| `modules/dashboard/locals.tf` | Added `kafka_observability = values(module.block_kafka_observability).*.result` to `blocks_results`; appended nine `kafka_*_widget` results to `widget_result` | Block output must be injected back into the row list, and each widget type must be included in the final Grafana panel list. |
| `modules/dashboard/alerts.tf` | Concatenated `module.block_kafka_observability_alerts` into `widget_alert_rules`; added kafka entry to `deep_merge_alert_configs`; added the alerts module | Same pattern as `block/service`. Dashboard-level `alerts` merge with per-row `alerts`. |
| `modules/dashboard/variables.tf` | Docs only: `alerts` description now mentions `kafka_observability` | No type/default change. Existing `alerts` input stays `any`. |
| `modules/dashboard/README.md` | Added consumer HCL example for the new block | Reviewers/consumers can copy usage. |
| `README.md` | Added the same example at root | Root README is what AWS-wrapper consumers usually read. |

We did **not** change:

- `application_dashboard` schema (`rows` was already `any`)
- `modules/grafana`, Loki, Prometheus, Tempo, VictoriaMetrics runtime modules
- alert contact points / notification policies
- AWS wrapper repository

Incidental: `modules/loki-stack/README.md` and `modules/victoria-metrics/README.md` may show provider-version table noise from `terraform_docs`. That is not Kafka behaviour.

### New files we added

| Path | What it is |
|------|------------|
| `modules/dashboard/widgets-kafka.tf` | Wires the nine `kafka/*` widget modules from `local.widget_config` (copy of `widgets-redis.tf` style) |
| `modules/dashboard/modules/blocks/kafka_observability/` | Block contract + the 5 dashboard rows (title + 4 panel rows) |
| `modules/dashboard/modules/widgets/kafka/<panel>/` | One small module per panel: `base.tf` PromQL, `locals.tf` selector, `variables.tf`, `output.tf` |
| `modules/dashboard/modules/alerts/block-kafka-observability/` | Builds the Grafana rule list from the row config |
| `modules/dashboard/tests/kafka-observability/` | Example dashboard with generic names + `terraform validate` |
| `docs/DMVP-10603-kafka-observability.md` | This review document |

Widget folders (9): `consumer_lag`, `consumer_lag_trend`, `consumer_group_members`, `empty_consumer_groups`, `connect_rest_up`, `connector_state`, `task_state`, `connect_totals`, `exporter_health`.

### Copied pattern (not a new architecture)

| Copied from | Used for |
|-------------|----------|
| `block/rds` / `block/redis` | Block `output.result` is a list of rows of widget objects |
| `widgets-redis.tf` | One `module` per widget type + `for_each` on `local.widget_config["kafka/..."]` |
| `modules/widgets/container/cpu` | Prometheus `expression` panels through `modules/widgets/base` |
| `modules/alerts/block-service` | Alert objects with `expr`, `pending_period`, `labels`, `annotations` fed into existing `widget_alerts` |

Difference vs Redis: Redis takes `redis_name`. Kafka takes `namespace` plus optional PromQL `extra_filters` / cluster label, because exporter identity varies.

### Panel layout the block emits

From `modules/blocks/kafka_observability/output.tf`:

1. Title: `text/title-with-collapse` = `block_name`
2. Lag (width 12) + lag trend (width 12)
3. Members (12) + empty groups (12)
4. Connect REST (8) + connector state (8) + task state (8)
5. Totals by state (12) + exporter health (12)

Alert lists (`critical_consumer_groups`, idle groups, stopped connectors, thresholds, URLs) are **not** block-module variables. They stay on the row object and are read by `alerts.tf` via `try(each.value.block.critical_consumer_groups, [])`. The block module only owns panel layout.

### How a PromQL selector is built (every panel)

Each widget `locals.tf` builds a selector like:

```text
{namespace="kafka",cluster="example-kafka",job=~"kafka-exporter|kafka-connect-exporter"}
```

from:

- `namespace="..."` if namespace is set
- `${cluster_label}="${cluster}"` only if both are set
- raw `extra_filters` string if non-empty

Then metrics look like `kafka_consumergroup_lag${local.selector}`.

### How alerts turn on

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

### Branch commits

1. `ec9dc4d` `feat(DMVP-10603): add Kafka observability dashboard block and alerts`
2. `5c74b7c` `docs(DMVP-10603): add Kafka observability reviewer document`

Size vs `main`: about 64 files, roughly +2100 / −17 lines, almost all under `modules/dashboard`.

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

Each rule includes `summary`, `description`, `component`, `metric`, `issue_phrase`, `impact`, and optional `dashboard_url` / `runbook`.

Grafana reduce: `function = last`, `equation = gt`, `threshold = 0` (the PromQL already encodes the condition). `settings_mode = replaceNN` with `0`.

Default labels: `priority = P1`, `severity = critical`. Scrape alert defaults to `P2` / `warning`.

Disable individual rules with:

```hcl
alerts = {
  enabled = true
  connector_failed    = { enabled = false }
  task_failed         = { enabled = false }
  connect_rest_down   = { enabled = false }
  consumer_group_lag  = { enabled = false }
  exporter_scrape     = { enabled = true }
}


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

- [ ] Existing file edits (`widgets_blocks.tf`, `locals.tf`, `alerts.tf`) only register the new type and do not change other blocks
- [ ] Scope is correct: reusable dashboard block + Grafana alerts only
- [ ] Row type `block/kafka_observability` is the right consumer interface
- [ ] Selectors are generic enough (`namespace`, `extra_filters`, optional cluster)
- [ ] Idle groups and stopped connectors are excluded as expected
- [ ] Lag alert PromQL is acceptable (`increase` on lag, then `sum by (consumergroup)`)
- [ ] Alert defaults are acceptable (service-like on; scrape opt-in)
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
