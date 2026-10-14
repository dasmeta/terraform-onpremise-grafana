# Implementation Plan: Preserve Existing Dashboard Queries

**Branch**: `feat/legacy-dashboard-query-compat` | **Date**: 2026-10-14 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/005-legacy-dashboard-compat/spec.md`

## Summary

Add an opt-in, dashboard-scoped compatibility mode that reproduces the dashboard query expressions used before the working-set-memory and rollout-pod-regex migrations. The mode is selected from the existing dashboard defaults object, is disabled by default, and changes only the nine affected dashboard widget modules. It does not suppress Grafana dashboard drift, change alert rules, or alter the modern query default.

## Technical Context

**Language/Version**: Terraform HCL; production module supports Terraform `~> 1.3`; native Terraform tests require `>= 1.7, < 2.0`.

**Primary Dependencies**: Grafana provider `~> 4.0`, `dasmeta/terraform-aws-grafanav12` wrapper, and the consumer YAML-to-Terraform generation workflow.

**Storage**: N/A; dashboard definitions are rendered as Grafana provider configuration.

**Testing**: Native `terraform test` with mocked Grafana provider; `terraform fmt`; existing repository pre-commit hooks; downstream Terraform Cloud plan review.

**Target Platform**: Terraform Cloud-managed Grafana configuration and a consumer production Grafana environment.

**Project Type**: Versioned Terraform module with a downstream wrapper and customer environment consumer.

**Performance Goals**: Render the selected dashboard deterministically with zero query-expression drift against its selected contract.

**Constraints**: Preserve the current production dashboard's legacy expressions only when opted in; modern expressions remain default; no change to alert-rule configuration or dashboard layout; no lifecycle ignore rule.

**Scale/Scope**: One dashboard-scoped Boolean compatibility option; nine affected widget modules; one downstream environment selection after the release chain.

## Constitution Check

*GATE: Passed before Phase 0 and re-checked after Phase 1.*

The generated Spec Kit constitution contains only unfilled template placeholders, so it defines no enforceable project-specific gates. The repository workflow is therefore governed by the module-development requirements: specification, plan, tasks, explicit review of the new input contract, Terraform tests, documentation, semantic versioning, and downstream plan validation. This plan satisfies those gates:

- The user-facing interface is a single grouped optional setting with a false default.
- The contract is backward compatible and dashboard scoped.
- Tests cover both selected behaviours and alert isolation.
- The release path is explicit: on-premises module, AWS wrapper, then consumer YAML and generated Terraform.

## Project Structure

### Documentation (this feature)

```text
specs/005-legacy-dashboard-compat/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── dashboard-query-compatibility.md
└── tasks.md
```

### Source Code (repository root)

```text
variables.tf                                      # Public application_dashboard defaults contract
modules/dashboard/
├── locals.tf                                     # Resolve dashboard compatibility selection
├── widgets-container.tf                          # Propagate to five affected container widgets
├── widgets-ingress.tf                            # Propagate to ingress memory widget
├── widgets-pod.tf                                # Propagate to three affected pod widgets
└── modules/widgets/
    ├── container/{memory,network,network-traffic,network-error,replicas}/
    ├── ingress/memory/
    └── pod/{cpu,memory,restarts}/                # Variables and query templates
tests/dashboard-query-compatibility/              # Native Terraform query-contract fixture
README.md and modules/dashboard/README.md         # Public configuration documentation
```

**Structure Decision**: Extend the existing dashboard defaults flow and widget modules. Do not create a parallel dashboard module or mutate generated customer Terraform.

## Implementation Sequence

1. Add `defaults.query_compatibility.legacy_dashboard_queries` to the public dashboard configuration contract. Its effective value is `false` when omitted.
2. Resolve that selection once in `modules/dashboard/locals.tf` and pass it only to the nine affected widget module calls.
3. Add the corresponding optional Boolean input to each affected widget module and render either the recorded legacy expression or the current expression. Leave alert modules and all other widget modules untouched.
4. Add a mocked Terraform test fixture that verifies the full legacy and modern expression sets, per-dashboard isolation, and alert-rule non-interference.
5. Update public documentation with a minimal YAML example and the bounded list of affected query families.
6. Run local formatting, validation, and focused Terraform tests. Review the changed dashboard JSON to ensure compatibility mode changes expressions only.
7. Release the on-premises module as a backward-compatible feature release, update and release the AWS wrapper, then select compatibility mode in the consumer Grafana YAML. Regenerate Terraform only through the approved workflow and confirm Terraform Cloud has no `grafana_dashboard.metrics` diff for the target dashboard.
