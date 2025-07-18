deploymentMode: SingleBinary # right now we support this simplest loki setup only, TODO: consider level up and support multi component loki

%{ if create_service_account }
serviceAccount:
  create: ${create_service_account}
  name: ${service_account_name}
  annotations:
%{for k, v in service_account_annotations }
    ${k}: "${v}"
%{~ endfor }
%{ endif }

# disable chart test and related canary setup(TODO: check this components, maybe they are something to have enabled)
test:
  enabled: false
lokiCanary:
  enabled: false

# TODO: for now disabled, it seems we can use this option to expose loki endpoint, it has options to configure ingress/auth
gateway:
  enabled: false

loki:
  auth_enabled: false
  commonConfig:
    replication_factor: 1
  singleBinary:
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
    resources:
      request:
        cpu: ${request_cpu}
        memory: ${request_mem}
      limits:
        cpu: ${limit_cpu}
        memory: ${limit_mem}

%{ if tonumber(num_replicas) > 1 }
  ingester:
    wal:
      enabled: true
    persistence:
      enabled: true
      size: 10Gi
    chunk_idle_period: 5m
    chunk_block_size: 262144
    max_chunk_age: 1h
    chunk_target_size: 1048576
    lifecycler:
      ring:
        kvstore:
          store: memberlist
        replication_factor: ${num_replicas}
      heartbeat_period: 10s
      join_after: 15s
  memberlistConfig:
    join_members:
      - loki-memberlist.monitoring.svc.cluster.local:7946
%{ else }
  ingester:
    lifecycler:
      ring:
        kvstore:
          store: inmemory
%{ endif }

  %{ if length(schema_configs) > 0 }
  schemaConfig:
    configs: ${schema_configs}
  %{ else }
  schemaConfig:
    configs: []
  %{ endif }

  storage: ${storage}

  %{ if log_volume_enabled }
  limits_config:
    volume_enabled: ${log_volume_enabled}
    max_query_length: 1h
    max_streams_per_user: 1000
    max_entries_limit_per_query: 5000
    ingestion_rate_mb: 16
    ingestion_burst_size_mb: 32
  %{ endif }

  retention_deletes_enabled: true
  retention_period: ${retention_period}
