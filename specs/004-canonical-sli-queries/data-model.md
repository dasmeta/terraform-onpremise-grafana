# Data Model

## SLI Query Definition

- `kind`: uptime or latency
- `period`: Prometheus duration selected by the consumer
- `metric_filter`: optional comma-separated label matcher fragment
- `status_policy`: non-5xx/all for uptime; 2xx/3xx for latency
- `unit`: percent for uptime; seconds for latency
- `zero_traffic_behavior`: no data

## Alert Rule Definition

- `sli_query`: expression following the matching SLI definition
- `interval`: alert evaluation range
- `threshold`: minimum uptime percent or maximum latency seconds
- `annotations`: rule-specific threshold, metric, impact, component, and resource metadata

No persistent entities or state transitions are introduced.
