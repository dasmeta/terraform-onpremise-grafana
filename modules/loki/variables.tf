variable "namespace" {
  type        = string
  description = "namespace for deployment of chart"
  default     = "monitoring"
}

variable "chart_version" {
  type        = string
  description = "loki chart version"
  default     = "6.30.1"
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
      send_logs_s3 = optional(object({
        enable         = optional(bool, true)
        bucket_name    = optional(string, "")
        aws_role_arn   = optional(string, "")
        retention_days = optional(number, 7) # remove log item after set days
      }), {})
      service_account = optional(object({
        enable      = optional(bool, true)
        name        = optional(string, "loki")
        annotations = optional(map(string), {})
      }), {})
      persistence = optional(object({
        enabled       = optional(bool, true)
        size          = optional(string, "20Gi")
        storage_class = optional(string, "gp2")
        access_mode   = optional(string, "ReadWriteOnce")
      }), {})
      schema_configs = optional(list(object({
        from         = optional(string, "2025-01-01")
        object_store = optional(string, "s3")
        store        = optional(string, "tsdb")
        schema       = optional(string, "v13")
        index = optional(object({
          prefix = optional(string, "index_")
          period = optional(string, "24h")
        }))
      })), [])
      storage          = optional(map(any), { type = "filesystem" })
      replicas         = optional(number, 1)
      retention_period = optional(string, "168h")
      resources = optional(object({
        request = optional(object({
          cpu = optional(string, "200m")
          mem = optional(string, "250Mi")
        }), {})
        limit = optional(object({
          cpu = optional(string, "400m")
          mem = optional(string, "500Mi")
        }), {})
      }), {})
    }), {})
    promtail = optional(object({
      enabled              = optional(bool, true)
      log_level            = optional(string, "info")
      server_port          = optional(string, "3101")
      clients              = optional(list(string), [])
      log_format           = optional(string, "logfmt")
      extra_scrape_configs = optional(list(any), [])
      extra_label_configs  = optional(list(map(string)), [])
      ignored_containers   = optional(list(string), [])
      ignored_namespaces   = optional(list(string), [])
    }), {})
  })
  description = "Values to pass to loki helm chart"
  default     = {}
}

variable "cluster_name" {
  type        = string
  default     = ""
  description = "name of the eks cluster"
}
