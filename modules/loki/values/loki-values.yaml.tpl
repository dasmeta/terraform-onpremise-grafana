loki:
  url: ${loki_url}
  image:
    repository: grafana/loki
    tag: 2.9.4
%{ if persistence_enabled }
  persistence:
    enabled: ${persistence_enabled}
    accessModes:
      - ${persistence_access_mode}
    size: ${persistence_size}
    storageClassName: ${persistence_storage_class}
%{ endif }

%{ if num_replicas > 1 }
  replicas: ${num_replicas}
%{ endif }

%{ if create_service_account }
  serviceAccount:
    create: ${create_service_account}
    name: ${service_account_name}
    annotations:
  %{for k, v in service_account_annotations }
      ${k}: "${v}"
  %{~ endfor }
%{ endif }

  resources:
    request:
      cpu: ${request_cpu}
      memory: ${request_mem}
    limits:
      cpu: ${limit_cpu}
      memory: ${limit_mem}

  config:
%{ if log_volume_enabled }
    limits_config:
      volume_enabled: ${log_volume_enabled}
%{ endif }

%{ if num_replicas > 1 }
    ingester:
      lifecycler:
        ring:
          kvstore:
            store: memberlist
          replication_factor: ${num_replicas}
        heartbeat_period: 10s
        join_after: 15s
    memberlist:
      join_members:
        - loki-memberlist:7946
%{ endif }

%{ if length(schema_configs_raw) > 0 }
    schema_config:
      configs:
        ${indent(8,schema_configs_yaml)}
%{ else }
    schema_config:
      configs: []
%{ endif }

%{ if length(storage_configs) > 0 }
    storage_config:
%{ for k, v in storage_configs }
      ${k}:
%{ for inner_key, inner_value in v }
        ${inner_key}: ${inner_value}
%{ endfor }
%{ endfor }
%{ else }
    storage_config: {}
%{ endif }

    limits_config:
      retention_period: ${retention_period}

promtail:
  enabled: ${promtail_enabled}
  config:
    logLevel: ${promtail_log_level}
    serverPort: ${promtail_server_port}
    clients:
%{~ for c in promtail_clients }
      - url: ${c}
%{ endfor }
    logFormat: ${log_format}
    snippets:
%{ if length(promtail_extra_label_configs_raw) > 0 }
      extraRelabelConfigs:
      ${indent(6, promtail_extra_label_configs_yaml)}
%{ else }
      extraRelabelConfigs: []
%{ endif }
%{ if length(promtail_extra_scrape_configs) > 0 }
      extraScrapeConfigs: |
        ${indent(8, promtail_extra_scrape_configs)}
%{ else }
      extraScrapeConfigs: ""
%{ endif }

fluent-bit:
  enabled: ${enabled_fluentbit}

test_pod:
  enabled: ${enabled_test_pod}
