# Quickstart: Default Service Alert Cleanup

## Prerequisites

- Terraform CLI available in the repository workspace.
- Existing provider/module lock state can be initialized by Terraform.
- No generated `.terraform` or state files should be committed.

## Validation Commands

Run formatting on the changed Terraform files:

```bash
terraform fmt -check modules/dashboard/alerts.tf modules/dashboard/modules/alerts/block-service/variables.tf modules/dashboard/modules/alerts/block-service/locals.tf modules/dashboard/modules/alerts/block-service/outputs.tf tests/dashboard-widget-alerts-enabled/1-example.tf
```

Initialize and validate the block-service alert module:

```bash
terraform -chdir=modules/dashboard/modules/alerts/block-service init
terraform -chdir=modules/dashboard/modules/alerts/block-service validate
```

Initialize and validate the dashboard module:

```bash
terraform -chdir=modules/dashboard init
terraform -chdir=modules/dashboard validate
```

Initialize and validate the root module:

```bash
terraform init
terraform validate
```

Run whitespace checks:

```bash
git diff --check
```

## Expected Results

- Default service alert labels are no longer forced to P1 by `modules/dashboard/alerts.tf`.
- `replicas_no` remains P1/critical because it represents no running replicas.
- CPU, memory, restart, job, replica state, HPA, and unavailable replica degradation alerts default to P2/warning.
- Network anomaly alerts default to P3/warning when explicitly enabled.
- Default HPA min/max rules are omitted unless enabled or configured with manual thresholds.
- Default network in/out anomaly rules are omitted unless explicitly enabled.
- Deployment services include an unavailable replicas rule:
  - Expression uses `kube_deployment_status_replicas_unavailable`.
  - Equation is `gt`.
  - Threshold is `0`.
  - Pending period is `30s`.
- Non-deployment workloads do not receive the deployment unavailable replicas rule.

## Cleanup

After local verification, remove generated Terraform artifacts if they were created:

```bash
rm -rf .terraform .terraform.lock.hcl modules/dashboard/.terraform modules/dashboard/.terraform.lock.hcl modules/dashboard/modules/alerts/block-service/.terraform modules/dashboard/modules/alerts/block-service/.terraform.lock.hcl
```
