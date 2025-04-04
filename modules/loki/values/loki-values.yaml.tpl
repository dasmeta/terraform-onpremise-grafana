loki:
  url: ${loki_url}

promtail:
  enabled: ${promtail_enabled}
  config:
    logLevel: ${promtail_log_level}
    serverPort: ${promtail_server_port}
    clients:
%{~ for c in promtail_clients }
      - url: ${c}
%{ endfor }

fluent-bit:
  enabled: ${enabled_fluentbit}

test_pod:
  enabled: ${enabled_test_pod}
