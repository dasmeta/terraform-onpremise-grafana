# Data Model: Loki SimpleScalable First-Class Support

**Feature**: `002-loki-simple-scalable`

## Entities

### LokiDeploymentConfig

| Field | Type | Description | Validation |
|-------|------|-------------|------------|
| deploymentMode | string | Topology: SingleBinary, SimpleScalable, Distributed | Must be one of allowed values |
| release_name | string | Helm release prefix for service DNS | Default `loki` |
| storage.type | string | Backend storage driver | SimpleScalable: not `filesystem` |
| read | object | Read component Helm values | replicas default 2 in SimpleScalable |
| write | object | Write component Helm values | replicas default 2 in SimpleScalable |
| backend | object | Backend component Helm values | replicas default 1 in SimpleScalable |
| schemaConfig | list | Index/chunk schema entries | object_store aligned to storage in SimpleScalable |
| compactor_options | object | Compactor settings | delete_request_store aligned to storage in SimpleScalable |

### PromtailConfig

| Field | Type | Description | Validation |
|-------|------|-------------|------------|
| clients | list(string) | Push endpoint URLs | Empty → module push_url default |
| enabled | bool | Deploy Promtail | Default true |

### ModuleOutputs (loki-stack)

| Output | Description |
|--------|-------------|
| query_url | Grafana / LogQL query endpoint |
| push_url | Promtail push endpoint (includes `/loki/api/v1/push`) |
| deployment_mode | Resolved deployment mode string |

## Relationships

- Root `loki_stack` variable → `module.loki` configs input
- `module.loki.query_url` → root Grafana datasource URL
- `module.loki.push_url` → Promtail default clients when `promtail.clients` empty

## State Transitions

```text
SingleBinary (default)
  └─ consumer sets deploymentMode=SimpleScalable + object storage
       → query_url switches to *-read
       → push_url switches to *-write
       → read/write/backend replicas populated
       → schema/compactor stores aligned
```

## Validation Rules

1. `deploymentMode ∈ {SingleBinary, SimpleScalable, Distributed}`
2. IF `deploymentMode = SimpleScalable` THEN `storage.type ≠ filesystem`
3. User-provided `read`/`write`/`backend` merge overrides defaults
