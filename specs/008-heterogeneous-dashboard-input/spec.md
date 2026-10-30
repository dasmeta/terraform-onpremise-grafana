# Feature Specification: Heterogeneous Application Dashboard Input

**Feature Branch**: `008-heterogeneous-dashboard-input`  
**Created**: 2026-10-30  
**Status**: Approved  
**Input**: Accept application dashboards whose rows use different block-specific shapes.

## User Scenarios & Testing

### User Story 1 - Preserve mixed dashboard rows (Priority: P1)

An operator supplies one application dashboard with service, SLA, and AWS SES rows without adding irrelevant placeholder fields.

**Independent Test**: A native Terraform test passes a dashboard containing heterogeneous row objects.

**Acceptance Scenarios**:

1. **Given** an application dashboard with service, SLA, and AWS SES rows, **When** Terraform plans the module, **Then** input conversion succeeds.
2. **Given** a dashboard with one row type, **When** Terraform plans the module, **Then** its existing behavior remains unchanged.

### Edge Cases

- Dashboard entries may have different `defaults`, `rows`, and block-specific alert structures.
- An empty dashboard list remains accepted.

## Requirements

- **FR-001**: The module MUST accept heterogeneous dashboard entries and rows without consumers padding unused attributes.
- **FR-002**: The module MUST preserve existing dashboard rendering behavior after accepting the input.
- **FR-003**: The module MUST include a native Terraform regression test for mixed row types.
- **FR-004**: The README MUST state that heterogeneous row shapes are supported.
- **FR-005**: SLA widgets with no explicit period MUST use their documented `1d` fallback.

## Success Criteria

- **SC-001**: The regression test fails with the former `list(object(...))` input contract and passes with the new contract.
- **SC-002**: The full native Terraform test suite passes.

## Assumptions

- Relaxing this input to `any` is backward compatible because the module already iterates dashboard entries dynamically.
- This change adds no provider resource or authentication behavior.
