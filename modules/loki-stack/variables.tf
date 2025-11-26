variable "namespace" {
  type        = string
  description = "namespace for deployment of chart"
  default     = "monitoring"
}

variable "create_namespace" {
  type        = bool
  description = "Whether create namespace if not exist"
  default     = true
}

variable "promtail_chart_version" {
  type        = string
  description = "promtail chart version"
  default     = "6.17.0"
}

variable "configs" {
  type = object({
    loki = optional(object({
      chart_version    = optional(string, "6.34.0")       # the loki chart version, NOTE: the helm versions >=6.35.0 bring loki-0 pod crash-loops with default configs, makes ure you test things before helm upgrade to newer versions
      release_name     = optional(string, "loki")         # the loki chart release name
      deploymentMode   = optional(string, "SingleBinary") # we have SingleBinary mode by default, and in this mode distributor, ingester, querier, ... and several other components are within single binary loki app
      replicas         = optional(number, 1)              # number of main loki replicas in SingleBinary mode, in SingleBinary mode it is recommended to have replica count always 1
      auth_enabled     = optional(bool, false)            # should authentication be enabled
      structuredConfig = optional(any, {})                # this provide structured way to pass the loki all configs that available in https://grafana.com/docs/loki/latest/configure/ , for additional field support here code change may be needed or one can use extra_configs option
      commonConfig = optional(object({                    # for more info check https://grafana.com/docs/loki/latest/configuration/#common_config
        replication_factor = optional(number, 1)          # the number of ingesters to write to and read from.
      }), {})
      resources = optional(object({ # resources of loki in SingleBinary mode
        requests = optional(object({
          cpu    = optional(string, "100m")
          memory = optional(string, "100Mi")
        }), {})
        limits = optional(object({
          cpu    = optional(string, "1500m")
          memory = optional(string, "2000Mi")
        }), {})
      }), {})
      serviceAccount = optional(object({ # the service account configs that will be assigned to loki main component
        enable      = optional(bool, true)
        name        = optional(string, "loki")
        annotations = optional(map(string), {})
      }), {})
      monitoring = optional(object({ # monitoring related configs
        serviceMonitor = optional(object({
          enabled = optional(bool, true) # whether service monitor is enabled
        }), {})
      }), {})
      ingress = optional(object({ # allows to have loki service accessible from external
        enabled = optional(bool, false)
        type    = optional(string, "nginx")
        public  = optional(bool, true)
        tls = optional(object({
          enabled       = optional(bool, true)
          cert_provider = optional(string, "letsencrypt-prod")
        }), {})
        annotations = optional(map(string), {})
        hosts       = optional(list(string), ["loki.example.com"])
        path        = optional(string, "/")
        path_type   = optional(string, "Prefix")
      }), {})
      schemaConfig = optional(list(object({           # Configures the chunk index schema and where it is stored. for more info check https://grafana.com/docs/loki/latest/configure/#schema_config
        from         = optional(string, "2025-01-01") # defines starting at which date this storage schema will be applied        from         = optional(string, "2025-01-01")
        object_store = optional(string, "filesystem")
        store        = optional(string, "tsdb")
        schema       = optional(string, "v13")
        index = optional(object({
          prefix = optional(string, "index_")
          period = optional(string, "24h")
        }), {})
      })), [{}])
      limits_config = optional(object({                                   # this allows setting limitations and enabling some features for loki. https://grafana.com/docs/loki/latest/configure/#limits_config
        max_query_length          = optional(string, "7d1h")              # the limit to length of chunk store queries. 0 to disable.
        retention_period          = optional(string, "360h")              # retention period to apply to stored data, only applies if retention_enabled=true in the compactor config. Must be either 0(disabled) or a multiple of 24h, 360h=15days
        deletion_mode             = optional(string, "filter-and-delete") # the Deletion mode, Can be one of 'disabled','filter-only', "filter-and-delete". When set to 'filter-only' or 'filter-and-delete', and if retention_enabled=true in the compactor config, then the log entry deletion API endpoints are available
        volume_enabled            = optional(bool, true)                  # enables Loki log-volume index queries what can be used in grafana visualize log volume (LogQL → bytes_over_time)
        allow_structured_metadata = optional(bool, true)                  # allow user to send structured metadata in push payload.
        discover_log_levels       = optional(bool, true)                  # discover and add log levels(detected_level) during ingestion, if not present already.
      }), {})
      compactor_options = optional(object({ # compactor component options, for retention the compactor must run/configured, in "SingleBinary" mode compactor runs in loki single binary and there is no need for compactor separate component so we need only
        retention_enabled    = optional(bool, true)
        working_directory    = optional(string, "/var/loki/compactor")
        delete_request_store = optional(string, "filesystem")
      }), {})
      persistence = optional(object({ # enable persistent disk and configure
        enabled      = optional(bool, true)
        size         = optional(string, "20Gi")
        storageClass = optional(string, "")
        selector     = optional(string, null)
        annotations  = optional(any, {})
      }), {})
      storage = optional(any, { # the storage where loki will place its data, Loki requires a bucket for chunks and the ruler
        type = "filesystem",
        filesystem = {
          chunks_directory    = "/var/loki/chunks"
          rules_directory     = "/var/loki/rules"
          admin_api_directory = "/var/loki/admin"
        }
        bucketNames = {
          chunks = "unused-for-filesystem"
          ruler  = "unused-for-filesystem"
          admin  = "unused-for-filesystem"
        }
      })

      # loki stack other components configs(in SingleBinary mode most of them as separate component are disabled)
      chunksCache = optional(object({            # memcached based cache service which being used for chunks caching and improves loki performance when querying data
        enabled         = optional(bool, true)   # whether enabled, we have this enabled by default, but can be disabled manually
        allocatedMemory = optional(number, 8192) # the memory in MBs we attach to this component, the pods requested memory being calculated based on expression round(allocatedMemory * 1.2)
      }), {})
      resultsCache = optional(object({           # memcached based cache service which being used for chunks caching and improves loki performance when querying data
        enabled         = optional(bool, true)   # whether enabled, we have this enabled by default, but can be disabled manually
        allocatedMemory = optional(number, 1024) # the memory in MBs we attach to this component, the pods requested memory being calculated based on expression round(allocatedMemory * 1.2)
      }), {})
      test           = optional(any, { enabled = false })               # helm tests configs
      lokiCanary     = optional(any, { enabled = false })               # the Loki canary pushes logs to and queries from this loki installation to test that it's working correctly
      ruler          = optional(any, { enabled = false, replicas = 0 }) # the internal loki alerting module, which we do not need as we are going to use grafana alerting mechanism
      compactor      = optional(any, { replicas = 0 })                  # compactor component, in SingleBinary mode this included in loki
      read           = optional(any, { replicas = 0 })                  # read component, in SingleBinary mode this included in loki
      write          = optional(any, { replicas = 0 })                  # write component, in SingleBinary mode this included in loki
      backend        = optional(any, { replicas = 0 })                  # backend component, in SingleBinary mode this included in loki
      ingester       = optional(any, { replicas = 0 })                  # ingester component, in SingleBinary mode this included in loki
      querier        = optional(any, { replicas = 0 })                  # querier component, in SingleBinary mode this included in loki
      queryFrontend  = optional(any, { replicas = 0 })                  # queryFrontend component, in SingleBinary mode this included in loki
      queryScheduler = optional(any, { replicas = 0 })                  # queryScheduler component, in SingleBinary mode this included in loki
      distributor    = optional(any, { replicas = 0 })                  # distributor component, in SingleBinary mode this included in loki
      indexGateway   = optional(any, { replicas = 0 })                  # indexGateway component, in SingleBinary mode this included in loki
      bloomBuilder   = optional(any, { replicas = 0 })                  # bloomBuilder component, in SingleBinary mode this included in loki
      bloomPlanner   = optional(any, { replicas = 0 })                  # bloomPlanner component, in SingleBinary mode this included in loki
      bloomGateway   = optional(any, { replicas = 0 })                  # bloomGateway component, in SingleBinary mode this included in loki

      extra_configs = optional(any, {}) # allows to pass extra/custom configs to loki helm chart, this configs will deep-merged with all generated internal configs and can override the default set ones. All available options can be found in for the specified chart version here: https://artifacthub.io/packages/helm/grafana/loki?modal=values
    }), {})
    # TODO: the promtail deprecated, consider to have this replaced with for example fluent/fluent-bit
    promtail = optional(object({ # promtail configs, which is the default tool we have to collect and push logs to loki
      enabled               = optional(bool, true)
      chart_version         = optional(string, "6.17.1") # the promtail chart version
      log_level             = optional(string, "info")
      server_port           = optional(string, "3101")
      clients               = optional(list(string), [])
      log_format            = optional(string, "logfmt")
      extra_scrape_configs  = optional(list(any), [])
      extra_label_configs   = optional(list(map(string)), [])
      extra_pipeline_stages = optional(any, [])
      ignored_containers    = optional(list(string), [])
      ignored_namespaces    = optional(list(string), [])
      extra_configs         = optional(any, {}) # allows to pass extra/custom configs to promtail helm chart, this configs will deep-merged with all generated internal configs and can override the default set ones. All available options can be found in for the specified chart version here: https://artifacthub.io/packages/helm/grafana/promtail?modal=values
    }), {})
  })
  description = "Values to pass to loki helm chart"
  default     = {}
}
