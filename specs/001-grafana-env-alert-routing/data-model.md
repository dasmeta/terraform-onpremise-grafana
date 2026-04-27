# Data Model: Multi-Environment Grafana Alert Routing

## Entity: EnvironmentRoutingIdentity
- **Fields**:
  - `name`: canonical environment identifier (for example `dev`, `stage`, `prod`)
  - `source`: how identity is resolved (`namespace`, `datasource`, or `explicit`)
  - `selector`: lookup value used by the selected source mode
- **Rules**:
  - Must be unique in module configuration scope.
  - Must be resolvable for every alert route that expects environment-specific channels.

## Entity: EnvironmentChannelMapping
- **Fields**:
  - `environment`: reference to `EnvironmentRoutingIdentity.name`
  - `channels`: target notification channels for that environment
- **Rules**:
  - `environment` must map to an existing routing identity.
  - `channels` must not be empty when environment routing is enabled.

## Entity: TopologyMode
- **Fields**:
  - `mode`: `same_cluster_multi_namespace` or `multi_cluster_central_grafana`
  - `defaults`: mode-specific fallback behavior
- **Rules**:
  - Must be explicit in examples and documented behavior.
  - Mode selection controls identity resolution precedence.

## Entity: AlertRoutingPolicy
- **Fields**:
  - `match_labels`: includes environment identity label
  - `target_channels`: resolved from `EnvironmentChannelMapping`
  - `fallback_behavior`: handling for missing/unmapped environment
- **Rules**:
  - Routing must isolate environments (no cross-environment delivery).
  - Fallback behavior must be explicit and safe.
