terraform {
  required_version = "~> 1.3"

  required_providers {
    grafana = {
      source  = "grafana/grafana"
      version = "~> 4.0"
    }
  }
}

# to customize the grafana hostname, scheme, and admin password set the following env: `export TF_VAR_grafana_hostname=your_grafana_hostname`, `export TF_VAR_grafana_scheme=https`, and `export TF_VAR_grafana_admin_password=your_grafana_admin_password`
variable "grafana_scheme" {
  type        = string
  description = "Grafana URL scheme (http or https)"
  default     = "http"
}

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

# you can start dev grafana server locally using `docker compose up -d` from `/tests` folder before running the test locally
provider "grafana" {
  url                  = "${var.grafana_scheme}://${var.grafana_hostname}"
  auth                 = "admin:${var.grafana_admin_password}"
  insecure_skip_verify = var.grafana_scheme == "http" # Skip TLS verification for HTTP, verify for HTTPS
}
