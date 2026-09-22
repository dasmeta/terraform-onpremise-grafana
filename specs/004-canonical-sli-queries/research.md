# Research: Canonical MSP Uptime and Latency

## Decision: Request-based availability

Use good requests divided by total requests. HTTP 5xx is provider failure; HTTP 499 is retained in total traffic but is not failed by default.

**Rationale**: A good/total ratio is directly aggregatable and matches SLI practice. Ingress 499 represents the client closing the request, so assigning it to provider downtime by default would overstate failure.

**Alternatives considered**: Probe-only availability misses real request outcomes. Treating 499 as failure is contract-specific and remains an override concern.

## Decision: Traffic-weighted average latency

Sum duration deltas across successful series, then divide by summed request-count deltas.

**Rationale**: This is the arithmetic mean for actual requests and matches the existing CloudBrowser latency-average-seconds metric.

**Alternatives considered**: Averaging per-series averages biases toward low-traffic series. A latency-threshold success ratio or p95 would be a different KPI, explicitly out of scope.

## Decision: Dashboard and alert range functions

Dashboard panels use `increase` for selected-period totals. Alerts use `rate` over their evaluation interval.

**Rationale**: Both yield the same ratio/mean semantics when numerator and denominator share an interval; `rate` is conventional for continuously evaluated alert rules.

## Primary references

- Prometheus query functions: https://prometheus.io/docs/prometheus/latest/querying/functions/
- ingress-nginx monitoring metrics: https://kubernetes.github.io/ingress-nginx/user-guide/monitoring/
- Google SRE SLO implementation guidance: https://sre.google/workbook/implementing-slos/
