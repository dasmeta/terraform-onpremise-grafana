# Implementation Plan: Global Disk Capacity Alerts

**Branch**: `002-alert-default-cleanup` | **Date**: 2026-07-23 | **Spec**: `specs/003-global-disk-alerts/spec.md`
**Input**: Feature specification from `specs/003-global-disk-alerts/spec.md`

## Summary

Add a reusable root-module default PVC disk-capacity alert and make VictoriaMetrics the shared Prometheus-compatible datasource default for generated alerts and dashboards when that datasource is enabled. The disk rule should evaluate all matching PVCs by default, alert above 90%, and remain configurable or disableable through the existing grouped `alerts` object.

## Technical Context

**Language/Version**: Terraform HCL using the repository's existing constraints
**Primary Dependencies**: Existing root `alerts` input, `modules/alerts` Grafana rule generation, application dashboard module defaults, bundled stack dashboard JSON
**Storage**: N/A
**Testing**: Terraform example validation, `terraform fmt`, `terraform validate`, `jq`, live PromQL shape check against VictoriaMetrics
**Target Platform**: Kubernetes clusters exposing kubelet PVC metrics to a Prometheus-compatible datasource
**Project Type**: Terraform module repository
**Constraints**: No client-specific names in Terraform artifacts; preserve custom alert rules and existing notification configuration
**Scale/Scope**: One generic disk alert rule per module deployment, plus shared VictoriaMetrics defaults for generated metric alerts and dashboards

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

- Root custom alert rules are passed directly from `var.alerts.rules` to `module.alerts` and keep their explicit datasource contract.
- Alert datasources are rule-level UIDs.
- VictoriaMetrics datasource UID is generated as `victoriametrics` when `var.victoria_metrics.enabled` is true.
- The existing Prometheus datasource UID is `prometheus`.
- Application dashboard metric widgets and block alerts derive from dashboard datasource defaults unless the caller sets widget or block-level overrides.
- The bundled stack dashboard routes panels through its `data_source` dashboard variable.

## Design

1. Add `alerts.disk_capacity` as a grouped optional object.
2. Build `local.default_disk_capacity_alert_rules` from that object.
3. Concatenate default disk rules with `var.alerts.rules` before passing rules to `module.alerts`.
4. Use shared metric datasource UID precedence: explicit datasource override where supported, then `victoriametrics` when enabled, then `prometheus`.
5. Feed that shared datasource default into disk alerts, application dashboard defaults, Prometheus-compatible widget fallbacks, dashboard block alerts, and generated Grafana datasource default flags.
6. Update the bundled stack dashboard datasource variable current value to `victoriametrics` without changing panel query expressions.
7. Add a Terraform example that exercises the global disk-alert and dashboard datasource defaults.

## Proposed File Changes

- `variables.tf`: add `alerts.disk_capacity` input object.
- `locals.tf`: add disk alert defaults and generated rule list.
- `main.tf`: route concatenated alert rules to the alerts module, use the concatenated list for count/folder calculations, and make VictoriaMetrics the Grafana default datasource when enabled.
- `modules/dashboard/`: inherit root metric datasource defaults in Prometheus-compatible widget and block-alert paths.
- `grafana_dashboard_files/grafana_stack_dashboard.json`: default the `data_source` variable to VictoriaMetrics.
- `tests/global-disk-alerts/`: add validation fixture and datasource assertions.

## Risks

- Consumers without kubelet volume stats may see NoData unless they disable or retune the alert.
- Enabling a default alert is behavior-affecting; the disable path must be documented and simple.
- Changing generated dashboard defaults is behavior-affecting for consumers relying on implicit Prometheus datasource selection; explicit datasource overrides remain available.
- Service Desk routing still depends on consumer notification policies and contact points.

## Validation

- Confirm VictoriaMetrics datasource UID/name from live Grafana.
- Confirm the PVC usage expression parses and returns data in a VictoriaMetrics datasource.
- Confirm the focused Terraform plan emits `victoriametrics` for generated dashboard block alerts and dashboard metric widgets.
- Run `terraform fmt -check`.
- Run `terraform validate` for the new example where provider setup allows.
- Run `jq empty` for the dashboard JSON.
- Run `git diff --check`.
