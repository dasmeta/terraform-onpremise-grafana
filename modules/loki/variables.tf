variable "namespace" {
  type        = string
  description = "namespace for deployment of chart"
  default     = "monitoring"
}

variable "chart_version" {
  type        = string
  description = "loki chart version"
  default     = "6.32.0"
}

variable "promtail_chart_version" {
  type        = string
  description = "promtail chart version"
  default     = "6.17.0"
}

variable "release_name" {
  type    = string
  default = "loki"
}

variable "configs" {
  type = object({
    loki = optional(object({
      url                = optional(string, "")
      log_volume_enabled = optional(bool, true)
      service_account = optional(object({
        enable      = optional(bool, true)
        name        = optional(string, "loki")
        annotations = optional(map(string), {})
      }), {})
      persistence = optional(object({
        enabled       = optional(bool, true)
        size          = optional(string, "20Gi")
        storage_class = optional(string, "")
        access_mode   = optional(string, "ReadWriteOnce")
      }), {})
      schema_configs = optional(list(object({
        from         = optional(string, "2025-01-01")
        object_store = optional(string, "filesystem")
        store        = optional(string, "tsdb")
        schema       = optional(string, "v13")
        index = optional(object({
          prefix = optional(string, "index_")
          period = optional(string, "24h")
        }))
      })), [])
      limits_config = optional(map(string), {})
      storage = optional(any, {
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
      replicas         = optional(number, 1)
      retention_period = optional(string, "168h")
      resources = optional(object({
        request = optional(object({
          cpu = optional(string, "1")
          mem = optional(string, "1500Mi")
        }), {})
        limit = optional(object({
          cpu = optional(string, "1500m")
          mem = optional(string, "2000Mi")
        }), {})
      }), {})
      ingress = optional(object({
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
    }), {})
    promtail = optional(object({
      enabled               = optional(bool, true)
      log_level             = optional(string, "info")
      server_port           = optional(string, "3101")
      clients               = optional(list(string), [])
      log_format            = optional(string, "logfmt")
      extra_scrape_configs  = optional(list(any), [])
      extra_label_configs   = optional(list(map(string)), [])
      extra_pipeline_stages = optional(any, [])
      ignored_containers    = optional(list(string), [])
      ignored_namespaces    = optional(list(string), [])
    }), {})
  })
  description = "Values to pass to loki helm chart"
  default     = {}
}
