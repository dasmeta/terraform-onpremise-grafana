# Implementation Plan: Global Disk Capacity Alerts

**Branch**: `002-alert-default-cleanup` | **Date**: 2026-07-23 | **Spec**: `specs/003-global-disk-alerts/spec.md`
**Input**: Feature specification from `specs/003-global-disk-alerts/spec.md`

## Summary

Add a reusable root-module default PVC disk-capacity alert. The rule should evaluate all matching PVCs by default, alert above 90%, default to the existing Prometheus datasource, and remain configurable or disableable through the existing grouped `alerts` object.

## Technical Context

**Language/Version**: Terraform HCL using the repository's existing constraints
**Primary Dependencies**: Existing root `alerts` input and `modules/alerts` Grafana rule generation
**Storage**: N/A
**Testing**: Terraform example validation, `terraform fmt`, `terraform validate`, `jq`, PromQL shape check
**Target Platform**: Kubernetes clusters exposing kubelet PVC metrics to a Prometheus-compatible datasource
**Project Type**: Terraform module repository
**Constraints**: No client-specific names in Terraform artifacts; preserve custom alert rules and existing notification configuration
**Scale/Scope**: One generic alert rule per module deployment, covering all matching PVCs by default

## Constitution Check

- **Repository-local change gate**: PASS. Changes are scoped to Terraform module locals, variables, tests/examples, and feature documentation.
- **Speckit evidence**: PASS. This package records the global disk-alert scope before module-impacting edits.
- **Backward compatibility gate**: PASS with one intentional behavior addition. A default alert is added but includes an explicit disable path.
- **Wrapper/interface gate**: PASS. The new input is grouped under the existing `alerts` object rather than adding unrelated flat variables.
- **Naming policy**: PASS. New examples use generic `example` and `test` placeholders only.

## Project Structure

```text
specs/003-global-disk-alerts/
├── spec.md
├── plan.md
├── tasks.md
└── checklists/
    └── requirements.md

locals.tf
main.tf
variables.tf
tests/global-disk-alerts/
├── 0-setup.tf
└── 1-example.tf
```

## Current State

- Root custom alert rules are passed directly from `var.alerts.rules` to `module.alerts`.
- Alert datasources are rule-level UIDs.
- The existing Prometheus datasource UID is `prometheus`.
- Dashboard JSON and application dashboard datasource defaults are outside this feature scope.

## Design

1. Add `alerts.disk_capacity` as a grouped optional object.
2. Build `local.default_disk_capacity_alert_rules` from that object.
3. Concatenate default disk rules with `var.alerts.rules` before passing rules to `module.alerts`.
4. Use datasource UID precedence: explicit disk alert datasource, then `prometheus`.
5. Leave dashboard JSON and application dashboard datasource defaults unchanged.
6. Add a Terraform example that exercises the global disk-alert configuration.

## Proposed File Changes

- `variables.tf`: add `alerts.disk_capacity` input object.
- `locals.tf`: add disk alert defaults and generated rule list.
- `main.tf`: route concatenated alert rules to the alerts module and use the concatenated list for count/folder calculations.
- `tests/global-disk-alerts/`: add validation fixture.

## Risks

- Consumers without kubelet volume stats may see NoData unless they disable or retune the alert.
- Enabling a default alert is behavior-affecting; the disable path must be documented and simple.
- Service Desk routing still depends on consumer notification policies and contact points.

## Validation

- Confirm the PVC usage expression shape is valid for Prometheus-compatible datasources.
- Run `terraform fmt -check`.
- Run `terraform validate` for the new example where provider setup allows.
- Run `jq empty` for the dashboard JSON.
- Run `git diff --check`.
