# AWS CloudWatch dashboard test

Example dashboard that uses only AWS CloudWatch–backed blocks. Run from this directory:

```bash
terraform init
terraform plan   # or apply
```

## Blocks used

| Block | Description | Key options |
|-------|-------------|-------------|
| **block/cloudwatch** | EC2 instance CPU, disk, network | `region`, `period`, `datasource_uid` |
| **block/rds** | RDS CPU, memory, network, connections, latency, IOPS | `db_identifiers`, `block_name`, `region`, `period`, `datasource_uid` |
| **block/elasticache_redis** | ElastiCache Redis metrics | `cache_cluster_ids`, `block_name`, `region`, `period`, `datasource_uid` |
| **block/ses** | SES sending quota, send/delivery, bounce/complaint rates, etc. | `region`, `period`, `datasource_uid`, **`sending_quota_standard_options`** (min/max for gauge) |
| **block/alb_ingress** | ALB connections, request count, response time, HTTP codes | **`load_balancer_arn`** (required), `region`, `period`, `datasource_uid` |

## Widget options (options, reduceOptions, standard_options)

- **options** — legend, tooltip, and **reduceOptions** (for gauge/stat panels). Example: `options = { reduceOptions = { calcs = ["sum"], fields = "", values = false } }` (Total vs Last).
- **standard_options** — min/max for panel scale (e.g. gauge). Example: `standard_options = { min = 0, max = 100000 }`.
- SES block exposes **sending_quota_standard_options** for the Sending Quota gauge (default `{ max = 100000 }`).

Ensure the Grafana datasource UID (e.g. `cloudwatch`) exists and points to AWS CloudWatch.
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
