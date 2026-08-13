variable "namespace" {
  type        = string
  description = "namespace to use for deployment"
  default     = "monitoring"
}

variable "create_namespace" {
  type        = bool
  description = "Whether create namespace if not exist"
  default     = true
}

variable "chart_version" {
  type        = string
  description = "victoria metrics cluster chart version"
  default     = "0.31.4"
}

variable "release_name" {
  type        = string
  description = "victoria metrics release name"
  default     = "victoria-metrics"
}

variable "configs" {
  type = object({
    retention_period = optional(string, "30d")
    vmstorage = optional(object({
      replica_count = optional(number, 3)
      storage_class = optional(string, "")
      storage_size  = optional(string, "100Gi")
      access_modes  = optional(list(string), ["ReadWriteOnce"])
    }), {})
    vminsert = optional(object({
      replica_count = optional(number, 2)
    }), {})
    vmselect = optional(object({
      replica_count = optional(number, 2)
    }), {})
  })
  description = "Values to send to VictoriaMetrics helm chart"
  default     = {}
}

variable "extra_configs" {
  type        = any
  default     = {}
  description = "Allows to pass extra/custom configs to victoria-metrics-cluster helm chart"
}
