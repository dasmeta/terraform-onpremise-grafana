## Mixed Metrics
This test case demonstrates how to configure Grafana alerts to monitor various aspects of your microservices. We have set up alerts for tracking restart counts, maximum replicas, and zero available replicas.

1. **Restarts**: Monitors the restart count of microservice containers. We have configured alerts for `App_1` microservice. The restart count is tracked using the `kube_pod_container_status_restarts_total` metric, and the threshold for triggering the alert is set to `> 2`.

2. **Autoscaling**: Tracks the maximum replicas used by the `App_2` microservice. The alert is triggered when the replica count exceeds or reaches 20. The `kube_deployment_status_replicas_available` metric is utilized for this purpose.

3. **Replica Count**: Monitors the availability of replicas for two microservices, `App_1` and `App_3`. The alerts are triggered when the available replica count falls below 1. The `kube_deployment_status_replicas_available` metric is used to track the replica availability.
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
