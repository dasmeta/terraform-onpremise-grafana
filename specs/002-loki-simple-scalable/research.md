# Research: Loki SimpleScalable First-Class Support

**Feature**: `002-loki-simple-scalable`  
**Date**: 2026-07-23

## Decision 1: Mode-aware service endpoints

**Decision**: Use `{release}-read` for Grafana queries and `{release}-write` for Promtail push in SimpleScalable; keep `{release}` for SingleBinary; use `{release}-gateway` for Distributed URL fallback.

**Rationale**: Matches Grafana Loki Helm chart service naming in SimpleScalable mode. Production issue confirmed logs only appeared after manually switching datasource to `loki-read`.

**Alternatives considered**:
- Single gateway for both read and write in SimpleScalable — rejected; chart exposes separate read/write services by default without gateway.
- Keep generic `loki` service URL — rejected; causes missing logs in production SimpleScalable deployments.

## Decision 2: SimpleScalable replica defaults

**Decision**: Default `read=2`, `write=2`, `backend=1` when `deploymentMode = SimpleScalable` and user does not set component replicas (merge user values on top).

**Rationale**: Helm chart defaults leave read/write/backend at 0 when switching from SingleBinary passthrough; scalable mode requires active components.

**Alternatives considered**:
- Require explicit replicas from consumer — rejected; error-prone and inconsistent with module opinionated defaults elsewhere.
- Higher defaults (e.g., 3/3/2) — rejected; 2/2/1 is minimal HA starting point; users can override.

## Decision 3: Storage guardrails

**Decision**: Fail validation when SimpleScalable uses `storage.type = filesystem`. Auto-align `schemaConfig.object_store` and `compactor_options.delete_request_store` to object storage type in SimpleScalable mode.

**Rationale**: SimpleScalable requires shared object storage; filesystem defaults are SingleBinary-oriented and cause silent misconfiguration.

**Alternatives considered**:
- Warn only at plan time — rejected; fail-fast prevents broken production deploys.
- Auto-switch storage type — rejected; implicit infrastructure changes are unsafe.

## Decision 4: Promtail clients typo

**Decision**: Read `var.configs.promtail.clients` (not `promtails.clients`); default to computed `push_url` when clients list is empty.

**Rationale**: Typo prevented user overrides from working; empty list should use mode-aware default.

## Decision 5: Root Grafana wiring

**Decision**: Root module consumes `module.loki[0].query_url` for Grafana datasource; submodule owns URL logic.

**Rationale**: Single source of truth; submodule usable independently in tests.

**Alternatives considered**:
- Duplicate URL logic in root `locals.tf` — rejected; drift risk between root and submodule.
