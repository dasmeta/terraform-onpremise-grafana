# Quickstart: Loki SimpleScalable First-Class Support

**Feature**: `002-loki-simple-scalable`

## Prerequisites

- Kubernetes cluster with Helm provider configured
- Object storage bucket/credentials for SimpleScalable (S3 example below)
- Terraform ~> 1.3

## 1. Validate URL contract (no cluster apply required)

```sh
cd tests/loki-simple-scalable
terraform init
terraform validate
terraform plan
```

**Expected outputs**:

| Output | Value |
|--------|-------|
| `simple_scalable_query_url` | `http://loki-read.monitoring.svc.cluster.local:3100` |
| `simple_scalable_push_url` | `http://loki-write.monitoring.svc.cluster.local:3100/loki/api/v1/push` |
| `single_binary_query_url` | `http://loki-sb.monitoring.svc.cluster.local:3100` |

## 2. Enable SimpleScalable in root module

```hcl
loki_stack = {
  enabled = true
  loki = {
    deploymentMode = "SimpleScalable"
    storage = {
      type = "s3"
      s3 = {
        region = "us-east-1"
        bucketnames = {
          chunks = "my-loki-chunks"
          ruler  = "my-loki-ruler"
          admin  = "my-loki-admin"
        }
      }
    }
    # Optional overrides:
    # write = { replicas = 3 }
  }
}
```

Apply root module — Grafana datasource and Promtail URLs update automatically.

## 3. SingleBinary → SimpleScalable migration

1. Provision object storage and configure `loki_stack.loki.storage`.
2. Set `loki_stack.loki.deploymentMode = "SimpleScalable"`.
3. Optionally tune `read`, `write`, `backend` replicas.
4. `terraform plan` — confirm datasource URL changes to `*-read`.
5. `terraform apply` — no manual Grafana datasource edits required.

## 4. Guardrail verification

```sh
# Should fail terraform validate:
# deploymentMode = "SimpleScalable" + storage.type = "filesystem"
```

## Acceptance Evidence

- [x] `terraform validate` passes at repo root
- [x] `terraform validate` passes in `tests/loki-simple-scalable/`
- [x] Plan outputs match URL contract in `contracts/loki-url-contract.md`
- [x] README includes deployment mode matrix and migration steps
