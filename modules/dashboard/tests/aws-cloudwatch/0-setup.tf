terraform {
  required_version = "~> 1.3"

  required_providers {
    grafana = {
      source  = "grafana/grafana"
      version = "~> 4.0"
    }
  }
}

# Customize via env: TF_VAR_grafana_hostname, TF_VAR_grafana_scheme, TF_VAR_grafana_admin_password
variable "grafana_scheme" {
  type        = string
  description = "Grafana URL scheme (http or https)"
  default     = "http"
}

variable "grafana_hostname" {
  type        = string
  description = "Grafana hostname"
  default     = "grafana.localhost"
}

variable "grafana_admin_password" {
  type        = string
  description = "Grafana admin password"
  default     = "admin"
  sensitive   = true
}

provider "grafana" {
  url                  = "${var.grafana_scheme}://${var.grafana_hostname}"
  auth                 = "admin:${var.grafana_admin_password}"
  insecure_skip_verify = var.grafana_scheme == "http"
}
