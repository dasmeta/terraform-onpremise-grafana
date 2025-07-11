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

  %{ if num_replicas > 1 }
  ingester:
    lifecycler:
      ring:
        kvstore:
          store: memberlist
        replication_factor: ${num_replicas}
      heartbeat_period: 10s
      join_after: 15s
  memberlistConfig:
    join_members:
      - loki-memberlist:7946
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
  %{ endif }

  retention_deletes_enabled: true
  retention_period: ${retention_period}
