## Maximum Replica Count
This test case demonstrates how to configure Grafana alerts for an application reaching its maximum replica count. The alerts will notify you when the available replicas of a specific microservice have reached the maximum value for an extended period.

In this test, we have set up two alert rules for different microservices, `App_1` and `App_2`, within the `Autoscaling Test` folder. The alerts are triggered based on the Prometheus datasource and the metric `kube_deployment_status_replicas_available`.

For each microservice, we have specified a filter to match the deployment name (`app-1-microservice` and `app-2-microservice`). The `mean` function is applied to aggregate the metric values, and the `eqaution`, `threshold` parameters are used to check if the replicas available are equal to or greater than 20.
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
