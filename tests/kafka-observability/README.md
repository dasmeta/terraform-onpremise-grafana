# Kafka observability root test

Consumer-facing example for `source = "dasmeta/grafana/onpremise"`. It enables optional Kafka rows on `application_dashboard`:

- `block/msk` → CloudWatch DEFAULT `AWS/Kafka`
- `block/kafka_observability` → `kafka-connect-status-exporter` through VictoriaMetrics

Dashboard-level alerts stay off. Kafka/MSK alerts turn on only when that row sets `alerts.enabled = true`. Dashboard-level `alerts.enabled` is ignored for these rows.

## 1. Validate (no apply, no live Grafana)

```bash
cd tests/kafka-observability
terraform init -backend=false
terraform validate
```

Expected: `Success! The configuration is valid.`

Dashboard-only fixtures also exist:

```bash
terraform -chdir=modules/dashboard/tests/kafka-observability init -backend=false
terraform -chdir=modules/dashboard/tests/kafka-observability validate

terraform -chdir=modules/dashboard/tests/msk-cloudwatch init -backend=false
terraform -chdir=modules/dashboard/tests/msk-cloudwatch validate
```

## 2. Plan against a local Grafana (optional)

Needs Docker Desktop Kubernetes or another kubeconfig. Does **not** apply to a shared Dev/Prod account from this repo.

```bash
export KUBE_CONFIG_PATH="$HOME/.kube/config"
export TF_VAR_grafana_hostname=grafana.localhost
export TF_VAR_grafana_admin_password=admin

cd tests/kafka-observability
terraform init
terraform plan
```

Do not run `terraform apply` unless you intend to install this stack locally.

## 3. Live Dev test plan (after consumer enablement)

Enable the same two rows in the environment YAML, then check Grafana. Do this in the consumer repo, not by applying this module repo.

| Case | Action | Expected |
|------|--------|----------|
| Growing lag | Pause or slow a consumer group so `MaxOffsetLag` stays above threshold for 15m | CloudWatch lag alert fires; Slack/Teams get it through existing routing |
| Failed Connect task | Force one task into `failed` | Task-failed Grafana alert fires |
| REST unavailable | Stop Connect REST or break the exporter Connect URL | `kafka_connect_rest_up` is `0`; REST alert fires |
| Exporter failure | Scale the exporter to 0 | `up==0` or `kafka_connect_rest_up` absent; exporter alert fires |
| Recovery | Restore consumer, task, REST, and exporter | Alerts resolve; missing lag stays `NoData`, not a silent 0 |

Keep `kafka-lag-exporter` until CloudWatch lag alerts are validated.
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
