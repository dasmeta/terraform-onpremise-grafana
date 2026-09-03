# Quickstart: VictoriaMetrics Native Stack

## 1. Validate Prometheus-only compatibility

```hcl
metrics_collector = "prometheus"

prometheus = {
  enabled = true
}

victoria_metrics = {
  enabled = false
}
```

Expected result:

- Prometheus is the only active scraper and default metrics datasource.
- independent kube-state-metrics and node-exporter are installed by default;
- each exporter has a Prometheus `ServiceMonitor`;
- no VMAgent or native VM scrape object exists.

## 2. Start a dual-backend migration

```hcl
metrics_collector = "prometheus"

prometheus = {
  enabled = true
}

victoria_metrics = {
  enabled = true
  operator = {
    chart_version = "0.67.2"
  }
}
```

Apply and verify that VictoriaMetrics storage is healthy while Prometheus
remains the active scraper. Grafana provisions both datasources and keeps
Prometheus as default.

Then switch only:

```hcl
metrics_collector = "victoria_metrics"
```

Expected result:

- Prometheus storage may remain installed, but its scraper is disabled;
- one VMAgent becomes active;
- module-owned discovery switches to native VM objects;
- the converter remains available for application-owned Prometheus monitors;
- VictoriaMetrics becomes Grafana's default metrics datasource.

## 3. Satisfy the application migration gate

Before removing Prometheus, inventory every application-owned:

- `ServiceMonitor`;
- `PodMonitor`;
- `PrometheusRule`;
- authenticated scrape endpoint;
- Prometheus `additional_scrape_configs` job;
- direct Alertmanager integration.

Applications must create and validate equivalent `VMServiceScrape`,
`VMPodScrape`, and `VMRule` resources where required. Authentication remains
application-owned through Kubernetes Secret selectors or mounted secret files.
Do not put token values in Terraform input.

Representative VictoriaMetrics queries that must return recent data:

```promql
kube_deployment_status_replicas_available
container_cpu_usage_seconds_total
container_memory_working_set_bytes
container_network_receive_bytes_total
kubelet_volume_stats_used_bytes
node_filesystem_avail_bytes
```

Also query at least one authenticated application metric such as
`projected_talk_replicas` before passing the gate.

## 4. Switch to VictoriaMetrics-only

```hcl
metrics_collector = "victoria_metrics"

prometheus = {
  enabled = false
}

victoria_metrics = {
  enabled = true
  agent = {
    kubelet_scrape_enabled  = true
    cadvisor_scrape_enabled = true
    resource_scrape_enabled = false
  }
}
```

Expected result:

- no kube-prometheus-stack Helm release;
- VictoriaMetrics Cluster and Operator remain installed;
- the Operator owns official VM CRDs;
- a dependent resources release owns VMAgent and native scrape objects;
- the Prometheus converter is disabled;
- independent exporters remain installed;
- no module-generated object uses `monitoring.coreos.com`;
- Grafana provisions VictoriaMetrics as the only metrics datasource.

## 5. Verify Terraform locally

Validate the production root module first, then run the standalone test
fixture from its own directory:

```bash
terraform fmt -check -recursive
terraform validate
cd tests/metrics-collector-selection
terraform init -backend=false -lockfile=readonly
terraform test
```

The focused test suite requires Terraform 1.7 or newer for mocked providers;
the module's public runtime constraint remains Terraform `~> 1.3`.

## 6. Verify the cluster after apply

Inspect releases and resources without changing cluster state:

```bash
helm list -n monitoring
kubectl get crd | grep operator.victoriametrics.com
kubectl get vmagent,vmservicescrape,vmpodscrape,vmnodescrape -A
kubectl get servicemonitor,podmonitor -A
kubectl get pods -n monitoring
```

In VMAgent targets, verify healthy targets for:

- kube-state-metrics;
- node-exporter;
- kubelet;
- cAdvisor;
- Tempo/Loki when their self-monitoring is enabled;
- each migrated application scrape.

In Grafana, run representative queries against the VictoriaMetrics datasource
and check a time range that starts after the latest apply. Existing historical
VictoriaMetrics samples remain on its PVCs.

## 7. Roll back safely

If a required metric is missing:

```hcl
metrics_collector = "prometheus"

prometheus = {
  enabled = true
}

victoria_metrics = {
  enabled = true
}
```

Reapply to resume the Prometheus collection path while retaining
VictoriaMetrics storage and history. Do not delete VictoriaMetrics PVCs.

## 8. Keep CRD cleanup manual

The module intentionally does not delete old Prometheus Operator CRDs. Remove
them only in a separate reviewed operation after confirming that no
`ServiceMonitor`, `PodMonitor`, `PrometheusRule`, rollback procedure, or other
controller depends on them. Deleting a CRD can delete all resources of that
kind.
