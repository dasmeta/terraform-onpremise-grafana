# Tasks: Global Disk Capacity Alerts

**Input**: Design documents from `specs/003-global-disk-alerts/`
**Prerequisites**: `spec.md`, `plan.md`

## Phase 1: Setup

- [x] T001 Confirm the scope is global PVC disk capacity, not client-specific ClickHouse.
- [x] T002 Verify live Grafana datasource UID/name for VictoriaMetrics.
- [x] T003 Verify `kubelet_volume_stats_*` metrics exist in VictoriaMetrics.

## Phase 2: Test First

- [x] T004 Add a Terraform example using `alerts.disk_capacity` overrides.
- [x] T005 Run validation before implementation and confirm the example fails because the input is unsupported.

## Phase 3: Implementation

- [x] T006 Add `alerts.disk_capacity` input schema in `variables.tf`.
- [x] T007 Generate a default disk-capacity alert rule in `locals.tf`.
- [x] T008 Pass generated default rules plus custom rules to `module.alerts` in `main.tf`.
- [x] T009 Include generated default alert folder names in shared folder creation.
- [x] T010 Keep the stack dashboard datasource and queries unchanged.

## Phase 4: Validation

- [x] T011 Run Terraform formatting checks.
- [x] T012 Run Terraform validation for the new example or explain any provider-related blocker.
- [x] T013 Run JSON validation for the dashboard after reverting dashboard edits.
- [x] T014 Run PromQL validation for the default expression shape.
- [x] T015 Run `git diff --check`.

## Phase 5: Handoff

- [x] T016 Summarize implemented behavior, validation evidence, Jira refinement state, and CloudBrowser tooling gap.
