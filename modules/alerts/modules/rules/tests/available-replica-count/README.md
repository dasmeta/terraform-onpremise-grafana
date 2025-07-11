## No Available Replicas
This test case demonstrates how to configure Grafana alerts for detecting when an application doesn't have any available replicas. The alerts will notify you when the available replicas of a specific microservice drop to zero.

In this test, we have set up two alert rules to detect when the available replicas of the microservices drop to zero. The alerts are organized within the `Replica Count Test` folder. They rely on the Prometheus datasource and the metric `kube_deployment_status_replicas_available`.

For each microservice, we have specified a filter to match the deployment name (`app-1-microservice` and `app-2-microservice`). The `last` function is used to process the metric values, respectively.

The `eqaution`, `threshold` parameters are used to check if the available replicas fall below 1, indicating that the application doesn't have any replicas.
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
