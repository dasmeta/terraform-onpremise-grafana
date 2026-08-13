# Implementation Plan: Default Service Alert Cleanup

**Branch**: `002-alert-default-cleanup` | **Date**: 2026-07-23 | **Spec**: `specs/002-alert-default-cleanup/spec.md`  
**Input**: Feature specification from `specs/002-alert-default-cleanup/spec.md`

## Summary

Clean up default service alert generation in the dashboard block-service alert module. The implementation removes the forced P1 label from dashboard service alert defaults, assigns impact-based labels per alert type, gates noisy/context-dependent alerts, and adds the reusable DS-10938 deployment unavailable replicas alert with `> 0` for `30s`.

## Technical Context

**Language/Version**: Terraform HCL modules using the repository's existing Terraform constraints  
**Primary Dependencies**: Existing dashboard alert module, Grafana alert rule module inputs, `isometry/deepmerge` provider  
**Storage**: N/A  
**Testing**: `terraform fmt`, `terraform validate`, module-level validation, example output inspection  
**Target Platform**: Kubernetes workloads monitored by Grafana and Prometheus-compatible metrics  
**Project Type**: Infrastructure Terraform module repository  
**Performance Goals**: Reduce alert noise without removing outage coverage  
**Constraints**: Preserve backward-compatible caller overrides and existing alert rule object shapes  
**Scale/Scope**: Default alert generation for service block alerts across deployment, daemonset, statefulset, job, and cronjob workloads

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **Repository-local change gate**: PASS. Changes are scoped to Terraform module files, generated docs, and examples.
- **Backward compatibility gate**: PASS. Existing alert objects remain generated through the same output contract and caller labels can override defaults.
- **Noise reduction gate**: PASS. HPA and network alerts are gated by explicit enablement or thresholds.
- **Operational severity gate**: PASS. P1 remains reserved for no running replicas; other defaults are warning-level.

## Project Structure

### Documentation (this feature)

```text
specs/002-alert-default-cleanup/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── checklists/
│   └── requirements.md
└── tasks.md
```

### Source Code (repository root)

```text
modules/dashboard/alerts.tf
modules/dashboard/modules/alerts/block-service/
├── variables.tf
├── locals.tf
├── outputs.tf
└── README.md
tests/dashboard-widget-alerts-enabled/
└── 1-example.tf
```

**Structure Decision**: Implement alert behavior inside `modules/dashboard/modules/alerts/block-service`, remove dashboard-level forced P1 defaults in `modules/dashboard/alerts.tf`, and update the existing enabled-alert example to show the new configurable alert surface.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| None | N/A | N/A |
