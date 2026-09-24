# Complete Kafka monitoring dashboard

Optional example that enables both Kafka rows with generic identifiers:

- `block/msk` — CloudWatch DEFAULT `AWS/Kafka` metrics (`cloudwatch`)
- `block/kafka_observability` — `kafka-connect-status-exporter` through VictoriaMetrics (`victoriametrics`)

Alerts stay off unless `alerts.enabled = true` is set on that row. Dashboard-level `alerts.enabled` does not enable MSK or Connect alerts.

## What this tests

| Item | Coverage |
|------|----------|
| **block/msk** | CPU, memory, data-log disk, bytes in/out, partition count, offline partitions, under-replicated partitions, max/sum consumer lag |
| **block/kafka_observability** | Connect REST, connector/task state, totals, exporter health |
| **alerts** | Opt-in MSK offline partitions and MaxOffsetLag; opt-in Connect REST/failed/exporter |
| **datasources** | `cloudwatch` and `victoriametrics` |

Validate with:

```bash
terraform init -backend=false
terraform validate
```

Do not hardcode customer-specific cluster, group, or connector names.

Environment YAML should only pass identifiers and datasource UIDs. Do not copy this module into an environment wrapper.

## Trade-off

Native MSK `MaxOffsetLag` / `SumOffsetLag` can detect backlog. They do **not** provide exact per-group active-member count. Do not alert on `ConnectionCount`.

Keep `kafka-lag-exporter` in the environment until these CloudWatch lag alerts are validated. Removal is a follow-up.
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.3 |
| <a name="requirement_grafana"></a> [grafana](#requirement\_grafana) | ~> 4.0 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_this"></a> [this](#module\_this) | ../.. | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_grafana_admin_password"></a> [grafana\_admin\_password](#input\_grafana\_admin\_password) | Grafana admin password | `string` | `"admin"` | no |
| <a name="input_grafana_hostname"></a> [grafana\_hostname](#input\_grafana\_hostname) | Grafana hostname | `string` | `"grafana.localhost"` | no |
| <a name="input_grafana_scheme"></a> [grafana\_scheme](#input\_grafana\_scheme) | Grafana URL scheme (http or https) | `string` | `"http"` | no |

## Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
