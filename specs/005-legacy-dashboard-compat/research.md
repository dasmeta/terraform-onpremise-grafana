# Research: Legacy Dashboard Query Compatibility

## Decision: use one grouped, dashboard-scoped opt-in

The public selection will be:

```yaml
application_dashboard:
  - name: Main Dashboard
    defaults:
      query_compatibility:
        legacy_dashboard_queries: true
```

**Rationale**: `application_dashboard[].defaults` already travels from the public module input to the dashboard widget defaults. Nesting the Boolean under `query_compatibility` keeps the new user-facing capability grouped, discoverable, and independently selectable for every dashboard. An omitted selection evaluates to `false`, preserving current module behaviour.

**Alternatives considered**:

- A module-wide Boolean: rejected because only one consumer production dashboard needs preservation; it would force legacy queries onto new dashboards.
- A lifecycle `ignore_changes` rule for the dashboard JSON: rejected because it hides all future dashboard changes, including intended corrections.
- Pinning an earlier release: rejected because `v1.29.2` already contained the newer memory and rollout-regex expressions.

## Decision: reproduce the two recorded historical query contracts

The legacy mode will reproduce the expressions before these two module commits:

| Historical change | Legacy behaviour to preserve | Affected widget modules |
|---|---|---|
| `7b40f31` | `container_memory_usage_bytes` instead of working-set memory; the earlier pod-memory rate form | container memory, ingress memory, pod memory |
| `aa9b768` | Earlier pod selector forms without primary/canary rollout matching | container network, container network traffic, container network error, container replicas, pod CPU, pod memory, pod restarts |

There are nine unique affected widget modules because pod memory belongs to both historical changes.

**Rationale**: These are the only dashboard-widget source changes that explain the production plan’s query drift. The legacy expressions are available verbatim in module history, making the compatibility contract deterministic and testable.

**Alternatives considered**:

- Reconstructing expressions from the Terraform Cloud dashboard diff: not selected as the sole source because the current authenticated session did not return the archived plan JSON. Repository history contains the source-of-truth pre-change expressions.
- Applying broad string substitutions to the complete dashboard JSON: rejected as brittle and likely to affect unrelated custom queries.

## Decision: isolate compatibility from alerts

Only dashboard widget modules will receive the compatibility value. Alert modules, their query logic, and `is_paused` propagation remain unchanged.

**Rationale**: The requested protection is for the current dashboard resource. The alert changes are separate desired corrections and must remain reviewable rather than being silently frozen.

## Decision: verify rendered query targets, not provider state

Use native `terraform test` with a mocked Grafana provider and assert the `widget_result` expressions of the dashboard module. Add a root-interface test or fixture assertion for propagation from `application_dashboard[].defaults`.

**Rationale**: This validates the public input and all rendered Grafana targets without a live Grafana server, credentials, or a Terraform apply.

## Release decision

The on-premises module needs a backward-compatible feature release after review; the AWS wrapper then needs a release that consumes it; a consumer can finally set the YAML option. Exact version numbers will follow the repositories’ release conventions at merge time, with semantic-versioning review required before tagging.
