# Quickstart: Prometheus-to-VictoriaMetrics Operator Rollout

This rollout keeps both backend releases enabled. Prometheus monitoring CRDs are
still owned by kube-prometheus-stack, so `prometheus.enabled = false` is not a
supported VictoriaMetrics collector configuration in this feature.

## 1. Preflight

Confirm there is no separately managed VictoriaMetrics Operator, VMAgent, or
native scrape object that would overlap this module:

```sh
helm list -A
kubectl get vmagent -A
kubectl get vmservicescrape,vmpodscrape -A
kubectl get crd podmonitors.monitoring.coreos.com servicemonitors.monitoring.coreos.com
```

Review any existing `VMAgent` or `VMServiceScrape` before applying. The module's
generated VMAgent uses `selectAllByDefault = true`.

## 2. Install the Operator while Prometheus remains active

```hcl
prometheus = {
  enabled = true
}

victoria_metrics = {
  enabled = true

  operator = {
    chart_version = "0.67.2"
  }

  agent = {
    name          = "victoria-metrics-agent"
    replica_count = 1
  }
}

metrics_collector = "prometheus"
```

Run:

```sh
terraform init
terraform validate
terraform plan
terraform apply
```

Expected converged state:

- Prometheus server is active.
- VictoriaMetrics cluster/PVCs are unchanged.
- VictoriaMetrics Operator is running.
- The old standalone `victoria-metrics-agent` Helm release is absent.
- No `VMAgent` custom resource exists.
- Source `PodMonitor` and `ServiceMonitor` objects may already have converted
  VictoriaMetrics counterparts, but those objects are inert without VMAgent.
- Prometheus remote-writes a validation copy to vminsert.
- The Operator Deployment has no `--controller.disableReconcileFor` argument;
  PodMonitor and ServiceMonitor conversion cannot be disabled through raw chart
  overrides.
- The Deployment has no caller-injected `WATCH_NAMESPACE` or converter-disable
  env entry; unrelated explicit Operator env entries remain supported and
  `envFrom` is intentionally blocked.

Verify:

```sh
kubectl get pods -n monitoring
kubectl get podmonitor,servicemonitor -A
kubectl get vmpodscrape,vmservicescrape -A
kubectl get vmagent -A
```

## 3. Verify monitor conversion and authorization references

For an application monitor in namespace `dev`:

```sh
kubectl get podmonitor -n dev -o yaml
kubectl get vmpodscrape -n dev -o yaml
```

Confirm that the converted endpoint retains the authorization type and Secret
name/key selector. Do not print the Secret value. A missing or forbidden Secret
must be treated as a rollout blocker.

The Operator resolves that Secret into the generated VMAgent configuration
Secret at runtime. Runtime conversion needs source-Secret reads, but the pinned
chart-owned ClusterRole grants cluster-wide wildcard verbs on `secrets` and
`secrets/finalizers`. Restrict and audit the Operator service account and access
to both the application Secret and generated configuration Secret. Do not print
either Secret while validating the rollout.

## 4. Drain the Prometheus remote-write queue

Keep this state for at least two scrape intervals:

```promql
max(prometheus_remote_storage_samples_pending) == 0
```

Also confirm these counters do not increase during the observation window:

```promql
increase(prometheus_remote_storage_samples_failed_total[5m])
increase(prometheus_remote_storage_samples_retried_total[5m])
```

Do not switch while pending samples remain or failed/retried counters are
increasing.

## 5. Switch the active collector

Change one value:

```hcl
metrics_collector = "victoria_metrics"
```

Plan and confirm:

- the Prometheus Helm release remains installed but its Prometheus server is
  disabled;
- the Operator release remains installed;
- one `VMAgent` object is added through Operator `extraObjects`;
- the kube-state-metrics Prometheus `ServiceMonitor` is disabled;
- one native kube-state-metrics `VMServiceScrape` named
  `<Service fullname>-victoria-metrics` is present with a 32 MiB endpoint
  limit; its distinct name avoids ownership collision with converter output;
- the VictoriaMetrics cluster and vmstorage PVC settings are unchanged;
- Grafana defaults to the VictoriaMetrics datasource.

Apply during an agreed handoff window:

```sh
terraform apply
```

The two Helm releases do not switch atomically. A bounded overlap or no-data gap
can occur during convergence.

## 6. Validate VMAgent and application metrics

```sh
kubectl get vmagent -n monitoring
kubectl get pods -n monitoring
kubectl get vmpodscrape -n dev
kubectl get vmservicescrape -A
```

Locate the operator-managed vmagent pod, then inspect its target page:

```sh
kubectl get pods -n monitoring -l app.kubernetes.io/name=vmagent
kubectl port-forward -n monitoring deployment/vmagent-victoria-metrics-agent 18429:8429
curl -sS http://127.0.0.1:18429/api/v1/targets
```

Confirm:

- the authorization-protected application target is healthy and has no last
  scrape error;
- expected application metrics such as `projected_talk_replicas` and
  `scheduled_outbound_calls_next_5m` are queryable from VictoriaMetrics;
- Kubernetes dashboard metrics for replicas, kubelet/cAdvisor, network, and
  volumes continue updating;
- Prometheus is not scraping the same targets.

For kube-state-metrics, inspect the generated object:

```sh
kubectl get vmservicescrape -A -o yaml
```

Its endpoint must use port `http`, `honorLabels: true`, and
`max_scrape_size: 32MiB`.

## 7. Exceptional inline scrape jobs

`victoria_metrics.agent.extra_scrape_configs` remains available for targets
without a monitor CR:

```hcl
victoria_metrics = {
  enabled = true
  agent = {
    extra_scrape_configs = [{
      job_name = "internal-exporter"
      static_configs = [{
        targets = ["internal-exporter.monitoring.svc.cluster.local:9090"]
      }]
    }]
  }
}
```

Never place tokens or passwords in this value. Prefer a source
`PodMonitor`/`ServiceMonitor` with a Secret selector for authenticated
application endpoints.

A temporary caller job named `kube-state-metrics` suppresses the module's
native `VMServiceScrape`. Remove that transition job after verifying the native
object; otherwise the caller remains responsible for `max_scrape_size`.

## 8. Roll back to Prometheus

Before rollback, require:

```promql
max(vmagent_remotewrite_pending_data_bytes) == 0
```

Confirm remote-write connection errors, retries, and dropped-packet counters are
not increasing. The default VMAgent queue is ephemeral, so removing an agent with
a backlog can lose queued samples.

Then set:

```hcl
metrics_collector = "prometheus"
```

Apply and verify that the VMAgent CR is gone, Prometheus is active again, and the
VictoriaMetrics vmstorage PVC identities are unchanged.

## 9. Expected invalid configuration

This configuration must fail with a message explaining Prometheus monitoring CRD
ownership:

```hcl
prometheus = {
  enabled = false
}

victoria_metrics = {
  enabled = true
}

metrics_collector = "victoria_metrics"
```

Removing kube-prometheus-stack requires a separate migration that independently
owns Prometheus monitor CRDs and replaces any remaining exporters/rules.
