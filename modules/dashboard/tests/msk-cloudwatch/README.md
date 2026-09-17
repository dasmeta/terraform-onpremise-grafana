# MSK CloudWatch dashboard test

Example dashboard module configuration using `block/msk` with generic cluster identifiers.

## Block covered

| Block | Metrics |
|-------|---------|
| **block/msk** | CPU, memory, bytes in/out, partition count, offline partitions, consumer lag |

## Usage

```sh
cd modules/dashboard/tests/msk-cloudwatch
terraform init
terraform validate
terraform plan
```

## Expected result

- Plan succeeds without errors
- Dashboard includes MSK CloudWatch panels for `example-msk-cluster`
- No client-specific cluster names in this fixture

## Optional alerting example

Add to the block row:

```hcl
alerts = {
  enabled = true
  offline_partitions = {
    threshold      = 0
    pending_period = "5m"
  }
}
```
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
