# Data Model: Legacy Dashboard Query Compatibility

## Dashboard query compatibility

| Field | Type | Default | Ownership | Validation |
|---|---|---:|---|---|
| `application_dashboard[].defaults.query_compatibility` | object | omitted | One dashboard | Optional grouped configuration object |
| `legacy_dashboard_queries` | Boolean | `false` | The containing dashboard | Must resolve to a Boolean; `true` selects the legacy contract |

## Effective selection

Each dashboard resolves its own effective value. It does not inherit a global setting and does not modify any other dashboard. The existing defaults-merging path continues to supply data-source and widget defaults unchanged.

## Query contract variants

| Variant | Selected when | Result |
|---|---|---|
| Modern | Setting is omitted or `false` | Current working-set-memory and rollout-aware pod selector expressions |
| Legacy | Setting is `true` | Expressions exactly matching the versions before `7b40f31` and `aa9b768` for the nine affected widget modules |

## Boundaries

- Dashboard titles, layout, panels not in the nine affected modules, folders, permissions, and data sources are not compatibility entities and must not change.
- Alert rules, alert query expressions, alert pause state, and notifications are outside the model.
