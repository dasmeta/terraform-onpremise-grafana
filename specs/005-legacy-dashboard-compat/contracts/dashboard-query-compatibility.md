# Dashboard Query Compatibility Contract

## Public configuration

```yaml
application_dashboard:
  - name: Main Dashboard
    defaults:
      query_compatibility:
        legacy_dashboard_queries: true
```

`legacy_dashboard_queries` is optional and defaults to `false`.

## Behaviour

| Configuration | Dashboard query result |
|---|---|
| Omitted | Current modern expressions |
| `false` | Current modern expressions |
| `true` | The v1.28.2 expressions described below |

## Legacy expression scope

| Widget module | Legacy contract |
|---|---|
| `container/memory` | Uses `container_memory_usage_bytes` for average and maximum targets. |
| `ingress/memory` | Uses `container_memory_usage_bytes` for average and maximum targets. |
| `pod/memory` | Uses the pre-working-set rate expressions and pre-rollout pod matcher. |
| `container/network` | Uses the pre-rollout container pod matcher. |
| `container/network-traffic` | Uses the pre-rollout pod matcher. |
| `container/network-error` | Uses the pre-rollout pod matcher. |
| `container/replicas` | Uses the pre-rollout pod matcher for phase and restart targets. |
| `pod/cpu` | Uses the pre-rollout pod matcher. |
| `pod/restarts` | Uses the pre-rollout pod matcher. |

No other dashboard widgets are changed. The setting has no effect on alert rules.

This is an upgrade-only compatibility path, not a setting for new dashboards. Modern queries retain working-set memory for OOM-risk visibility and rollout-aware selectors. The compatibility path will be removed in a future major release after consumers migrate to the modern query contract.

## Compatibility guarantees

- Existing callers that omit the setting retain the current module output.
- Dashboards can select different variants in the same module invocation.
- This setting is not a dashboard lifecycle ignore rule; unrelated dashboard changes remain visible in Terraform plans.
