# Kafka observability dashboard block

Example dashboard module configuration using `block/kafka_observability` with generic identifiers.

## What this tests

| Item | Coverage |
|------|----------|
| **block/kafka_observability** | Consumer lag, lag trend, members, empty groups, Connect REST/state/totals, exporter health |
| **alerts** | Critical empty-member + lag growth, connector/task FAILED, REST down, optional scrape failure |
| **selectors** | `namespace`, optional `cluster`/`cluster_label`, and `extra_filters` |

Validate with:

```bash
terraform init -backend=false
terraform validate
```

Do not hardcode customer-specific cluster, group, or connector names.
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
