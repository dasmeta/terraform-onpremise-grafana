tempo:
  storage:
    trace:
      backend: ${storage_backend}
      local:
        path: /var/tempo/traces
  metricsGenerator:
    enabled: ${metris_generator_enabled}
    remoteWriteUrl: ${metrics_generator_remote_url}

  overrides:
    defaults:
      metrics_generator:
        processors:
          - service-graphs
          - span-metrics

  persistence:
    enabled: ${persistence_enabled}
    size: ${persistence_size}
    storageClassName: ${persistence_class}

serviceMonitor:
  enabled: ${enable_service_monitor}

serviceAccount:
  create: true
  name: ${service_account_name}
  annotations:
  %{for k, v in service_account_annotations }
      ${k}: "${v}"
  %{~ endfor }
