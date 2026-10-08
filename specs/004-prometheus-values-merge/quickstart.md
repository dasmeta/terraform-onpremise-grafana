# Quickstart: Validate the Prometheus values merge backport

1. Run the focused VictoriaMetrics-enabled test fixture from
   `tests/prometheus-victoria-metrics-merge` and confirm the rendered values
   contain the caller `nodeSelector` and `tolerations` together with the
   generated remote-write URL.
2. Confirm the pre-change baseline fails because the rendered effective values
   omit the caller's `nodeSelector` and `tolerations`.
3. Apply the local-map correction and rerun the fixture.
4. Confirm the rendered values contain the caller fields and the generated
   VictoriaMetrics remote-write URL.
5. Run `tests/prometheus-without-victoria-metrics-merge` and use its README
   assertion to confirm the same caller fields are retained while
   `remoteWrite` is absent.
6. Run formatting and Terraform validation from the repository root.
7. Compare the plan with the v1.28.0 baseline and confirm no standalone
   exporter release or other component-ownership change appears.

## Current local validation

On 2026-10-08, the post-change VictoriaMetrics-enabled and
VictoriaMetrics-disabled fixtures both planned successfully and their value
assertions passed: the enabled case retained the caller node selector and
toleration with the generated `remoteWrite` URL, while the disabled case
retained those caller fields with no generated `remoteWrite`. The topology
guards found no standalone kube-state-metrics, node-exporter, VictoriaMetrics
Operator, or VMAgent Helm release.
