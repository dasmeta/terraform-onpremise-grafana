# NGINX SLI Query Contract

## Uptime dashboard

```promql
100 * sum(increase(nginx_ingress_controller_requests{status!~"5.."<optional-filter>}[<period>])) / sum(increase(nginx_ingress_controller_requests{<filter>}[<period>]))
```

## Average latency dashboard

```promql
sum(increase(nginx_ingress_controller_request_duration_seconds_sum{status=~"2..|3.."<optional-filter>}[<period>])) / sum(increase(nginx_ingress_controller_request_duration_seconds_count{status=~"2..|3.."<optional-filter>}[<period>]))
```

Alert expressions replace `increase` with `rate`, use the alert interval, and suppress a zero denominator with `unless ... == 0`.

`<optional-filter>` is empty or starts with `, `. `<filter>` is the trimmed raw matcher fragment and may be empty inside `{}`.
