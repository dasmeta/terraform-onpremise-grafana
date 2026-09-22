# Local Docker Desktop test

Minimal live example for verifying the DMVP-10430 disruption-safety change against a real cluster:
the grafana database must no longer render a PodDisruptionBudget permitting zero evictions.

Only grafana and its created mysql database are enabled. Tempo, loki and prometheus are off — none is
involved in the change, and each costs several pods and a volume on a laptop.

## Requirements

Docker Desktop with Kubernetes enabled, an nginx ingress controller, and a hosts entry:

```sh
kubectl get ingressclass          # expect: nginx
echo "127.0.0.1 grafana.localhost" | sudo tee -a /etc/hosts
```

The hosts entry matters for more than the browser: the grafana terraform provider connects to
`http://grafana.localhost` to create dashboards and alert rules, so it fails without it.

## Run

```sh
export KUBE_CONFIG_PATH=~/.kube/config
terraform init
terraform apply
```

## What to check

```sh
# THE FIX: there must be no PodDisruptionBudget for the database
kubectl get pdb -A

# grafana comes up with the new default of 2 replicas
kubectl get deploy -l app.kubernetes.io/name=grafana

# reachable through nginx
curl -sI http://grafana.localhost/login | head -1
```

## Why `database.node_selector = {}` is set

The module defaults it to `{ "karpenter.sh/capacity-type" = "on-demand" }`, which is correct on a
karpenter cluster and unschedulable here — no Docker Desktop node carries that label, so the mysql pod
would sit Pending forever and the change would look like the cause. Setting `{}` also exercises the
documented opt-out.

## Why the default alert is disabled

`alerts.disk_capacity` defaults to enabled, resolves its folder to `application-dashboard`, and then LOOKS
THAT FOLDER UP with a data source. The folder only exists if an `application_dashboard` entry created it,
and a minimal config has none — so the apply fails with `folder with title application-dashboard not found`
on a folder nothing was ever asked to create. Pre-existing module behaviour, unrelated to this change;
`tests/metrics-collector-selection` works around it the same way.

## What this cannot verify

The on-demand placement itself, which needs karpenter. The local run covers the budget removal, the
replica defaults and the ingress path.
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.3 |
| <a name="requirement_grafana"></a> [grafana](#requirement\_grafana) | ~> 4.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~> 2.17 |

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
| <a name="input_grafana_hostname"></a> [grafana\_hostname](#input\_grafana\_hostname) | Grafana hostname for ingress and provider URL | `string` | `"grafana.localhost"` | no |
| <a name="input_grafana_scheme"></a> [grafana\_scheme](#input\_grafana\_scheme) | Grafana URL scheme (http or https) | `string` | `"http"` | no |

## Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
