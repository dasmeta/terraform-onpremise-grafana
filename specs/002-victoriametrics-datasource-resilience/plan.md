# Implementation Plan: VictoriaMetrics Datasource Resilience

**Branch**: `fix-datasource-problem` | **Date**: 2026-07-22 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/002-victoriametrics-datasource-resilience/spec.md`

## Summary

Persist the validated VictoriaMetrics datasource resilience mitigation as default generated Helm values in `modules/victoria-metrics`, and persist the Grafana-created MySQL primary pod/PDB mitigation as default generated Helm values in `modules/grafana`. Add Terraform plan-time tests that prove default module output includes the required resilience values while preserving existing override paths.

## Technical Context

**Language/Version**: Terraform `~> 1.3`  
**Primary Dependencies**: Helm provider `~> 2.17`, VictoriaMetrics `victoria-metrics-cluster` chart  
**Storage**: Existing VictoriaMetrics persistent volume settings, unchanged  
**Testing**: `terraform test` against `modules/victoria-metrics`  
**Target Platform**: Kubernetes through Helm release values  
**Project Type**: Terraform module repository  
**Performance Goals**: Reduce datasource error fan-out during one-at-a-time storage pod unavailability  
**Constraints**: Keep existing module interface and `extra_configs` override behavior  
**Scale/Scope**: `modules/victoria-metrics` and `modules/grafana` defaults plus focused tests

## Constitution Check

The repo-local constitution file still contains placeholders, so no project-specific gates are enforceable from it. Applicable module governance comes from the Terraform module developer skill:

- Current repository module state: existing wrapper modules at `modules/victoria-metrics` and `modules/grafana` render Helm releases for VictoriaMetrics, Grafana, and the module-created Grafana MySQL database.
- Gaps versus bundled internal standards: no README for the VictoriaMetrics submodule and no existing submodule tests for these defaults; this change adds focused tests but does not broaden documentation scope beyond the requested fix.
- Wrapper-preservation assessment: preserve the existing narrow wrapper and default-oriented interface; do not expose a broad set of upstream chart flags.
- Provider collection checked: not applicable because this is an improvement to an existing module, not new-module creation.
- Candidate upstream modules considered: not applicable.
- Chosen wrapper baseline: existing `victoria-metrics-cluster` Helm chart wrapper.
- Constitution repository source used: Terraform module developer internal standards and Speckit module workflow.
- Corresponding Speckit evidence: `specs/002-victoriametrics-datasource-resilience/`.
- Module-change gate compatibility: expected to pass with `spec.md`, `plan.md`, and `tasks.md`.
- Fallback rationale: no scratch template or new provider module needed.
- Proposed file changes: `modules/victoria-metrics/main.tf`, `modules/victoria-metrics/tests/defaults.tftest.hcl`, `modules/grafana/main.tf`, `modules/grafana/tests/mysql-defaults.tftest.hcl`, this Speckit package.
- Potential breaking changes: default storage/write amplification increases because RF=2 writes samples twice; default Grafana MySQL PDB blocks voluntary disruption of the singleton primary; consumers can override through existing chart values.
- Potential interface widening changes: none.
- Conflicts requiring approval: none identified for the requested default.

## Project Structure

### Documentation (this feature)

```text
specs/002-victoriametrics-datasource-resilience/
├── spec.md
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
modules/victoria-metrics/
├── main.tf
├── variables.tf
├── versions.tf
├── outputs.tf
└── tests/
    └── defaults.tftest.hcl

modules/grafana/
├── main.tf
├── variables.tf
├── versions.tf
├── outputs.tf
├── values/
│   └── grafana-values.yaml.tpl
└── tests/
    └── mysql-defaults.tftest.hcl
```

**Structure Decision**: Keep the changes inside the existing VictoriaMetrics and Grafana submodules and add module-local Terraform tests.

## Complexity Tracking

No constitution violations or extra complexity exceptions are required.
