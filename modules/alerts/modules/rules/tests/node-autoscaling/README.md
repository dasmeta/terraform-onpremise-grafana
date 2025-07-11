# Node Autoscaling
This test case demonstrates how to configure Grafana alerts for monitoring Node count in the cluster.

Basically it notifies you when node autoscaling reaches
- to its maximum, in our case: `$B >= 8`,
- to more count than the half of maximum: `$B >= 6`,
- to its minimum, in our case: `$B <= 2`.

Replace the values in the conditions with your real numbers.

## Usage
Please, note that we pass `null` value to `filters` variable. It's needed when we use such Prometheus metrics which don't get any filters when querying.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_grafana"></a> [grafana](#requirement\_grafana) | >= 3.7.0 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_this"></a> [this](#module\_this) | ../../ | n/a |

## Resources

No resources.

## Inputs

No inputs.

## Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
