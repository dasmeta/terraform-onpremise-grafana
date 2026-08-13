# Quickstart: VictoriaMetrics Datasource Resilience

1. Run the module test from the repository root:

   ```bash
   terraform -chdir=modules/victoria-metrics test
   terraform -chdir=modules/grafana test
   ```

2. Confirm the test verifies default generated Helm values for:

   - `vminsert.extraArgs.replicationFactor = 2`
   - `vmselect.extraArgs.replicationFactor = 2`
   - `vmselect.extraArgs.dedup.minScrapeInterval = "1ms"`
   - `vmselect.extraArgs.search.skipSlowReplicas = true`

3. Optional chart-render check:

   ```bash
   terraform -chdir=modules/victoria-metrics test
   terraform -chdir=modules/grafana test
   ```
