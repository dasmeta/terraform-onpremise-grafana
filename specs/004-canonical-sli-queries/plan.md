# Implementation Plan: Canonical MSP Uptime and Latency

**Branch**: `fix/msp-sli-queries` | **Date**: 2026-09-22 | **Spec**: [spec.md](spec.md)

## Summary

Correct the NGINX ingress SLA/SLO widget and alert expressions so uptime is non-5xx requests divided by all requests and latency is a request-weighted average over 2xx/3xx responses. Preserve histogram mode, make the period and filter selectors valid, and prove the contract through native Terraform tests.

## Technical Context

**Language/Version**: Terraform HCL, Terraform `~> 1.3`
**Primary Dependencies**: Existing local dashboard widget modules; Grafana panel JSON model
**Storage**: N/A
**Testing**: `terraform test`, `terraform validate`, `terraform fmt -check -recursive`
**Target Platform**: Grafana backed by a Prometheus-compatible data source
**Project Type**: Terraform module repository
**Performance Goals**: One aggregate series per KPI panel/alert after label aggregation
**Constraints**: Backward-compatible module inputs; no new KPI; no customer identifiers; no live deployment
**Scale/Scope**: Four NGINX SLA/SLO module surfaces: two widgets and two alert rules

## Constitution Check

- Downstream repository confirmed: `terraform-onpremise-grafana`.
- Speckit evidence: `specs/004-canonical-sli-queries/{spec,plan,tasks}.md`.
- Module-change gate: expected to pass once package and tests are committed.
- Current state: opinionated local widget/alert modules already own the query defaults.
- Standards gap: current period is hard-coded, empty filters can form invalid selectors, latency has the wrong unit/meaning, and alerts diverge from panels.
- Wrapper preservation: existing input objects, outputs, and local-module layout remain intact; only defaults/derived expressions change.
- Repository convention: `required_providers` remains in existing `versions.tf`; no provider or version change.
- Governance source: `terraform-module-developer` constitution references for Speckit evidence, compatibility, tests, and naming.
- Modern Capabilities Rule: improve mode; no wholly net-new provider/platform ability.
- Potential breaking change: latency panel semantics change from percentage under 2.5 seconds to average seconds. This is intentional and user-approved because CloudBrowser metric 26 is average seconds.
- Interface widening: none.
- Conflicts requiring approval: none.

## Project Structure

### Documentation

```text
specs/004-canonical-sli-queries/
├── spec.md
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/query-contract.md
└── tasks.md
```

### Source Code

```text
modules/dashboard/modules/widgets/sla-slo-sli/
├── nginx_availability/
│   ├── base.tf
│   ├── variables.tf
│   ├── locals.tf
│   └── tests/query_contract.tftest.hcl
└── nginx_latency/
    ├── base.tf
    ├── variables.tf
    ├── locals.tf
    └── tests/query_contract.tftest.hcl

modules/dashboard/modules/alerts/block-sla-nginx/
├── locals.tf
├── outputs.tf
└── tests/query_contract.tftest.hcl
```

**Structure Decision**: Preserve each focused module and add small locals/tests beside the expressions they own.

## Design Decisions

1. Use `increase` for dashboard period totals and `rate` for continuously evaluated alert windows. Ratios are semantically equivalent for a shared interval.
2. Build optional matcher suffixes once in locals so empty filters cannot leave a dangling comma.
3. Leave zero-denominator results absent. Do not coerce missing traffic to good or bad service.
4. Use existing absolute latency thresholds (2, 2.5, 3 seconds) for the new seconds-valued panel.
5. Preserve the status-distribution/latency-distribution histogram modes; they are diagnostic panels, not exported metrics.

## Proposed File Changes

- Update both NGINX widget `base.tf` expressions, titles, descriptions, units, thresholds, and configurable periods.
- Add widget `locals.tf` files for filter normalization.
- Change availability `period` default to `1d` and document both period inputs.
- Update alert locals/outputs to share canonical status rules, weighted latency, and correct annotations.
- Add native Terraform contract tests to all three module boundaries.
- Regenerate touched module READMEs only if the repository tooling changes their documented inputs.
