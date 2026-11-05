# Plan

Use the Grafana chart's `envRenderSecret` capability. Render `$__env{GF_DATABASE_PASSWORD}` into `grafana.ini` and pass the password only as the Secret value. Keep the public module interface unchanged.

Modern capability classification: supported; the Grafana Helm chart supports `envRenderSecret` and Grafana supports `$__env{...}` configuration expansion.
