terraform {
  required_version = "~> 1.3"

  required_providers {
    grafana = {
      source  = "grafana/grafana"
      version = "~> 4.0"
    }
  }
}

# to customize the grafana hostname and admin password set the following env: `export TF_VAR_grafana_hostname=your_grafana_hostname` and `export TF_VAR_grafana_admin_password=your_grafana_admin_password`
variable "grafana_hostname" {
  type        = string
  description = "Grafana hostname for ingress and provider URL"
  default     = "grafana.localhost"
}

variable "grafana_admin_password" {
  type        = string
  description = "Grafana admin password"
  default     = "admin"
  sensitive   = true
}

# it is supposed to have docker desktop with kubernetes enabled, so that grafana will be created and provider will be able to connect to it
provider "grafana" {
  url                  = "http://${var.grafana_hostname}"
  auth                 = "admin:${var.grafana_admin_password}"
  insecure_skip_verify = true # Skip TLS verification for local testing without certificates
}
