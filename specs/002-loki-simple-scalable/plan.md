# Implementation Plan: Loki SimpleScalable First-Class Support

**Branch**: `002-loki-simple-scalable` | **Date**: 2026-07-23 | **Spec**: [spec.md](./spec.md)  
**Input**: Feature specification from `specs/002-loki-simple-scalable/spec.md`

## Summary

Add first-class Loki SimpleScalable support to `terraform-onpremise-grafana` by making Grafana datasource and Promtail URLs deployment-mode aware, applying SimpleScalable replica defaults and storage guardrails, exporting `query_url`/`push_url` from `modules/loki-stack`, and documenting migration with a dedicated test example.

## Technical Context

**Language/Version**: Terraform HCL ~> 1.3  
**Primary Dependencies**: Grafana Loki Helm chart (~6.34.0), Promtail Helm chart, existing `modules/loki-stack`, root Grafana datasource wiring  
**Storage**: Object storage required for SimpleScalable (S3/Azure/GCS); filesystem allowed for SingleBinary  
**Testing**: `terraform validate`, `terraform plan` in `tests/loki-simple-scalable/`  
**Target Platform**: Kubernetes clusters running on-prem Grafana stack  
**Project Type**: Infrastructure Terraform module repository  
**Performance Goals**: No regression for existing SingleBinary deployments  
**Constraints**: Single PR; backward-compatible SingleBinary URLs; user replica overrides preserved  
**Scale/Scope**: `modules/loki-stack`, root `main.tf`/`locals.tf`/`variables.tf`, README, one new test folder

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **Refined requirement gate**: PASS (`spec.md` complete with bounded scope).
- **Clarification gate**: PASS (assumptions documented; no open markers).
- **Scope gate**: PASS (single repo, single PR, explicit out-of-scope list).
- **Backward compatibility gate**: PASS (SingleBinary unchanged unless mode explicitly set).

## Project Structure

### Documentation (this feature)

```text
specs/002-loki-simple-scalable/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── loki-url-contract.md
├── checklists/
│   └── requirements.md
└── tasks.md
```

### Source Code (repository root)

```text
modules/loki-stack/
  locals.tf      # mode-aware URLs, defaults, schema/compactor alignment
  main.tf        # promtail.clients fix, effective component configs
  outputs.tf     # query_url, push_url, deployment_mode
  variables.tf   # deploymentMode + storage validation
main.tf          # Grafana datasource uses module query_url
locals.tf        # loki_query_url from module output
variables.tf     # root-level loki_stack validation
README.md        # deployment modes, URL matrix, migration
tests/loki-simple-scalable/
  0-setup.tf
  1-example.tf
  README.md
.terraformignore
```

**Structure Decision**: All behavioral changes live in `modules/loki-stack` with thin root wiring; tests validate submodule outputs directly.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| None | N/A | N/A |
