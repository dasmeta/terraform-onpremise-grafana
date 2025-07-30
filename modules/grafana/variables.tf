
variable "namespace" {
  type        = string
  description = "namespace to use for deployment"
  default     = "monitoring"
}

variable "grafana_admin_password" {
  type        = string
  description = "admin password"
  default     = ""
}

variable "chart_version" {
  type        = string
  description = "grafana chart version"
  default     = "9.2.9"
}

variable "mysql_chart_version" {
  type        = string
  description = "mysql chart version"
  default     = "13.0.2"
}

variable "mysql_release_name" {
  type        = string
  description = "name of grafana mysql helm release"
  default     = "grafana-mysql"
}

variable "datasources" {
  type        = list(map(any))
  description = "A list of datasources configurations for grafana."
  default     = []

}

variable "configs" {
  type = object({
    resources = optional(object({
      request = optional(object({
        cpu = optional(string, "1")
        mem = optional(string, "2Gi")
      }), {})
      limit = optional(object({
        cpu = optional(string, "2")
        mem = optional(string, "3Gi")
      }), {})
    }), {})
    database = optional(object({           # configure external(or in helm created) database base storing/persisting grafana data
      enabled       = optional(bool, true) # whether database based persistence is enabled
      create        = optional(bool, true) # whether to create mysql databases or use already existing database
      name          = optional(string, "grafana")
      type          = optional(string, "mysql") # when we set external database we can set any sql compatible one like postgresql or ms sql, but when we create database it supports only mysql and changing this field do not affect
      host          = optional(string, null)    # it will set right host for grafana mysql in case create=true
      user          = optional(string, "grafana")
      password      = optional(string, null)     # if not set it will use var.grafana_admin_password
      root_password = optional(string, null)     # if not set it will use var.grafana_admin_password
      persistence = optional(object({            # allows to configure created(when database.create=true) mysql databases storage/persistence configs
        enabled       = optional(bool, true)     # whether to have created in k8s mysql database with persistence
        size          = optional(string, "20Gi") # the size of primary persistent volume of mysql when creating it
        storage_class = optional(string, "")     # default storage class for the mysql database
      }), {})
      extra_flags = optional(string, "--skip-log-bin") # allows to set extra flags(whitespace separated) on grafana mysql primary instance, we have by default skip-log-bin flag set to disable bin-logs which overload mysql disc and/but we do not use multi replica mysql here

      # TODO: implement multi-replica/redundant grafana mysql database creation possibility
    }), {})
    persistence = optional(object({ # configure pvc base storing/persisting grafana data(it uses sqlite DB in this mode), NOTE: we use mysql database for data storage by default and no need to enable persistence if DB is set, so that we have persistence disable here by default
      enabled       = optional(bool, false)
      type          = optional(string, "pvc")
      size          = optional(string, "20Gi")
      storage_class = optional(string, "")
    }), {})
    ingress = optional(object({
      type        = optional(string, "nginx")
      public      = optional(bool, true)
      tls_enabled = optional(bool, true)

      annotations = optional(map(string), {})
      hosts       = optional(list(string), ["grafana.example.com"])
      path        = optional(string, "/")
      path_type   = optional(string, "Prefix")
    }), {})

    service_account = optional(object({
      enable      = optional(bool, true)
      annotations = optional(map(string), {})
    }), {})

    redundancy = optional(object({
      enabled                  = optional(bool, false)
      max_replicas             = optional(number, 4)
      min_replicas             = optional(number, 1)
      redundancy_storage_class = optional(string, "")
    }), {})

    trace_log_mapping = optional(object({
      enabled       = optional(bool, false)
      trace_pattern = optional(string, "trace_id=(\\w+)")
    }), {})
    replicas  = optional(number, 1)
    image_tag = optional(string, "11.4.2")
  })

  description = "Values to construct the values file for Grafana Helm chart"
  default     = {}
}
