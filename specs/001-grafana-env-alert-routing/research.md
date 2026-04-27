# Research: Same-Cluster Multi-Environment Grafana Alert Routing

## Decisions

### Decision: Use canonical environment routing identity
- **Rationale**: A consistent environment identity enables strict per-environment routing while preserving namespace-driven dashboard workflows.
- **Alternatives considered**:
  - Namespace-only routing without explicit matcher examples: rejected because routing intent becomes implicit and error-prone.

### Decision: Scope current ticket to same-cluster topology only
- **Rationale**: Current ticket is explicitly constrained to same-cluster multi-namespace routing support.
- **Alternatives considered**:
  - Include multi-cluster central Grafana in same ticket: rejected and moved to separate follow-up ticket.

### Decision: Preserve existing dashboard namespace-variable behavior
- **Rationale**: Existing consolidated dashboard workflows are already used in production.
- **Alternatives considered**:
  - Breaking migration to new-only model: rejected because ticket scope does not include broad dashboard redesign.

### Decision: Mirror equivalent capability into `terraform-aws-grafanav12`
- **Rationale**: Requirement explicitly asks for synchronized behavior across module variants.
- **Alternatives considered**:
  - Separate follow-up ticket: rejected for mirror parity because same-cluster behavior must stay aligned across module variants.

### Decision: Route unresolved environment alerts to `ops-fallback`
- **Rationale**: Prevents silent cross-environment leakage while preserving operational visibility for misconfigured alerts.
- **Alternatives considered**:
  - Drop silently: rejected because it hides incidents.
  - Send to global default environment channel: rejected because it risks cross-environment confusion.
