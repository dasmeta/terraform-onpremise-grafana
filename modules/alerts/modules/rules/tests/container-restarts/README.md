## High Restart Count
This test case demonstrates how to configure Grafana alerts for monitoring high restart counts of microservice containers. The alerts will notify you when the restart count of a specific container exceeds a predefined threshold.

In this test, we have set up two alert rules to monitor the restart count of microservice containers. The alerts are categorized within the `Restarts Test` folder. They utilize the Prometheus datasource and the metric `kube_pod_container_status_restarts_total`.

For each microservice, we have specified a filter to match the container name (`app-1-container` and `app-2-container`). The `mean` function is used to aggregate the restart count values.

The `eqaution`, `threshold` parameters are employed to check if the restart count exceeds the thresholds for each microservice. When the conditions are met, indicating a high restart count, the alerts will be triggered.
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
