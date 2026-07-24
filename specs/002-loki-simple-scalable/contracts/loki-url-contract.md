# Loki URL Contract

**Feature**: `002-loki-simple-scalable`  
**Module**: `modules/loki-stack`

## Outputs

| Output | Type | Description |
|--------|------|-------------|
| `query_url` | string | In-cluster HTTP URL for LogQL queries (Grafana datasource) |
| `push_url` | string | In-cluster HTTP URL for log push (Promtail clients) |
| `deployment_mode` | string | Resolved `deploymentMode` value |

## URL Resolution Matrix

Let `R` = release name, `N` = namespace.

| deploymentMode | query_url | push_url |
|----------------|-----------|----------|
| SingleBinary | `http://R.N.svc.cluster.local:3100` | `http://R.N.svc.cluster.local:3100/loki/api/v1/push` |
| SimpleScalable | `http://R-read.N.svc.cluster.local:3100` | `http://R-write.N.svc.cluster.local:3100/loki/api/v1/push` |
| Distributed | `http://R-gateway.N.svc.cluster.local:80` | `http://R-gateway.N.svc.cluster.local:80/loki/api/v1/push` |

## Promtail Clients Contract

- IF `configs.promtail.clients` is non-empty → use provided list verbatim
- ELSE → `[push_url]`

## Root Module Contract

When `var.loki_stack.enabled = true`, Grafana datasource entry:

```hcl
{ type = "loki", name = "Loki", url = module.loki[0].query_url }
```

## Validation Contract

- Invalid: `deploymentMode = "SimpleScalable"` + `storage.type = "filesystem"`
- Valid modes: `SingleBinary`, `SimpleScalable`, `Distributed`

## Test Verification

`tests/loki-simple-scalable/` MUST produce plan outputs matching this matrix for SingleBinary and SimpleScalable examples.
