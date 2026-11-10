# Implementation Plan: Heterogeneous Application Dashboard Input

**Branch**: `008-heterogeneous-dashboard-input` | **Date**: 2026-10-30 | **Spec**: [spec.md](spec.md)

## Summary

Relax `application_dashboard` from a homogeneous list of objects to `any`. The module already iterates dashboard entries and their rows dynamically, so this preserves block-specific values without Terraform forcing a common row type.

## Technical Context

**Language**: Terraform HCL  
**Testing**: Terraform native `.tftest.hcl` tests  
**Scope**: Root `variables.tf`, `README.md`, and a root-module regression test.

## Compatibility and Governance

- This is an interface relaxation, not a breaking change: all formerly accepted values remain valid.
- The module remains responsible for dashboard parsing; no consumer-specific field is introduced.
- Modern Capabilities Rule: not applicable; no provider capability is added.
- Speckit evidence: this package contains `spec.md`, `plan.md`, and `tasks.md`.

## File Changes

1. Change `application_dashboard` in `variables.tf` to `any`, explicitly restore the former optional defaults in locals, and make the SLA period fallback accept an omitted period.
2. Add `tests/heterogeneous-application-dashboard/1-heterogeneous-input.tftest.hcl` with service, SLA, and AWS SES rows.
3. Add a README compatibility note.

## Validation

Run `terraform fmt -recursive`, `terraform init -backend=false`, `terraform validate`, and `terraform test`.
