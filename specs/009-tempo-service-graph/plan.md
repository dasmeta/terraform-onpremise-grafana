# Tempo Service Map Integration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` (recommended) or `superpowers:executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the built-in Tempo datasource and Tempo metrics generator automatically support service maps when VictoriaMetrics is deployed, with optional bounded dimensions and collector-consistent queries.

**Architecture:** Keep the public change within the existing root `tempo` object and pass the resolved sibling integration state through narrowly scoped child-module inputs. Grafana extends its existing Tempo datasource JSON in place using the root's selected collector UID; the Tempo Helm child emits processors and optional labels only when the root has enabled VictoriaMetrics.

**Tech Stack:** Terraform HCL, Grafana provider, Helm provider, Grafana Tempo chart, native Terraform tests.

---

**Branch**: `009-tempo-service-graph` | **Date**: 2026-11-03 | **Spec**: [spec.md](spec.md)
**Input**: Configure the built-in Tempo datasource to use the selected metrics
collector for service-map and trace-metric queries, and expose optional
service-graph metric dimensions.

## Summary

The root module already creates one Tempo datasource (`uid = "tempo"`) and
selects a metrics datasource for `tracesToMetrics`. Extend that datasource
rather than creating a second one. When VictoriaMetrics is enabled, the
selected metrics collector remains the Tempo service-map and traces-to-metrics
backend, and the node graph plus both Tempo metrics processors are enabled. A
narrow `tempo.service_graph_dimensions` list remains empty by default and, when
supplied, is emitted to both processor configurations.

## Technical Context

**Language/Version**: Terraform HCL, module constraint `~> 1.3`
**Primary Dependencies**: `grafana/grafana ~> 4.0`, `hashicorp/helm ~> 2.17`,
Grafana Tempo Helm chart `1.23.3`
**Testing**: Terraform native `.tftest.hcl` files with mocked providers
**Target Platform**: Kubernetes-hosted Grafana, Tempo, and VictoriaMetrics
**Project Type**: Terraform module repository
**Constraints**: Preserve one Tempo datasource and existing behavior when
VictoriaMetrics is disabled; do not raise the Terraform consumer-version floor.
**Scope**: Root datasource wiring, the root `tempo` object, the Tempo Helm child,
one native regression test, README documentation, and Speckit evidence.

## Research and Compatibility

- Grafana Tempo requires the `service-graphs` and `span-metrics` processors to
  generate the series used by service-map views. Their processor configuration
  belongs under `overrides.defaults.metrics_generator`.
  [Grafana Tempo configuration](https://grafana.com/docs/tempo/latest/configuration/)
- `enable_client_server_prefix` is supported by the service-graphs processor,
  but not by span metrics. It must therefore be emitted only beneath
  `processor.service_graphs`.
- Extra dimensions are read from trace resource/span attributes, are added only
  when present, and increase series cardinality. This justifies an empty default
  and an explicit opt-in list.
  [Grafana metrics-generator troubleshooting](https://grafana.com/docs/tempo/latest/troubleshooting/metrics-generator/)
- The net-new capability is **supported**: it uses existing Helm values and
  Grafana datasource JSON fields rather than a deprecated provider capability.
  No provider or Terraform constraint changes are needed.

## Current State and Standards Assessment

- `main.tf` creates the built-in `Tempo` datasource and `modules/grafana/locals.tf`
  assigns its stable UID and default JSON. The module is the correct owner.
- `variables.tf` already groups Tempo settings under `tempo`; adding an optional
  `service_graph_dimensions` field preserves that coherent interface. Its inline
  comment will describe the cardinality effect.
- `modules/tempo` writes caller Helm values before module-owned values, so a
  new explicit child input can make the documented dimensions behavior
  deterministic without widening `extra_configs`.
- The repository has a tracked Speckit package for this change. The local
  `.specify/feature.json` is stale, so Speckit helper commands must be invoked
  with `SPECIFY_FEATURE_DIRECTORY=specs/009-tempo-service-graph`.
- Repository baseline gaps are pre-existing and out of scope: there is no
  `examples/` directory, native test files are nested despite the canonical
  direct-`tests/` layout, and all visible GitHub validation workflows use
  `continue-on-error: true`. This change adds its test directly in `tests/` but
  does not modify unrelated automation.

## Interface and State Impact

`tempo.service_graph_dimensions` is a backward-compatible optional list with a
default of `[]`. Existing callers retain their existing Tempo Helm values. When
VictoriaMetrics is enabled, the existing `grafana_data_source.this["Tempo"]`
resource changes JSON in place; no datasource address changes and no duplicate
Tempo datasource are introduced. Enabling processors starts new metric series
and remote-write traffic, so the README must call out the operational cost.

## Proposed File Changes

1. `variables.tf`: add documented `tempo.service_graph_dimensions` as
   `optional(list(string), [])`.
2. `main.tf`: pass the existing resolved selected-collector UID to the Grafana
   child alongside the VictoriaMetrics-enabled state for the Tempo child.
3. `modules/grafana/variables.tf` and `modules/grafana/locals.tf`: accept an
   internal Tempo metrics datasource UID and a separate service-graph enabled
   state. Conditionally add `serviceMap` and `nodeGraph` JSON to the existing
   Tempo datasource while retaining its UID and Loki link.
4. `modules/tempo/variables.tf` and `modules/tempo/locals.tf`: accept the
   internal enabled state and dimensions list, then conditionally configure
   `service-graphs` and `span-metrics` processors under Tempo overrides.
5. `tests/tempo-service-graph.tftest.hcl` and
   `tests/tempo-service-graph-tempo.tftest.hcl`: add native plan assertions for
   root datasource wiring and direct Tempo Helm values respectively. Separate
   files avoid native-test provider type conflicts between the two module roots;
   the root test includes the deployed-VM/Prometheus-selected migration state.
6. `README.md`: document automatic datasource behavior, processor activation,
   and the opt-in cardinality trade-off.
7. `specs/009-tempo-service-graph/tasks.md`: record the executable TDD steps.

## Validation

1. Run the new test before implementation and confirm its assertions fail
   because the service-map fields and dimensions contract do not exist.
2. Run it again after the minimal implementation and confirm all runs pass.
3. Run `terraform fmt -check -recursive`, `terraform init -backend=false`,
   `terraform validate`, and `terraform test` from the repository root.
4. Run `pre-commit run --files` for all modified tracked files.
5. Inspect `git diff origin/main...HEAD` for an in-place datasource update and
   no unrelated state-address changes.

## Delivery Sequence

1. Merge and release this upstream module as a conventional `feat` change.
2. Confirm the resulting registry version is available.
3. Open a separate AWS-wrapper PR that pins that exact published version. Do
   not guess the release version or merge a wrapper reference before publication.

## Approval and Governance

- Speckit evidence: `specs/009-tempo-service-graph/spec.md`, this plan, and
  `tasks.md` are required before module-source edits.
- The repository constitution is an uncustomized template, so shared module
  standards are sourced from the active Terraform-module workflow.
- The user explicitly approved the narrow optional interface and automatic
  VictoriaMetrics behavior. No unresolved breaking-change or interface-widening
  approval remains.
