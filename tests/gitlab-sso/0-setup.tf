terraform {
  required_version = "~> 1.3"

  required_providers {
    grafana = {
      source  = "grafana/grafana"
      version = "~> 4.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.17"
    }
  }
}

# set the following env: `export TF_VAR_gitlab_client_id=your_gitlab_client_id` and `export TF_VAR_gitlab_client_secret=your_gitlab_client_secret`
variable "gitlab_client_id" {
  type        = string
  description = "GitLab OAuth application client ID"
  sensitive   = true
}

variable "gitlab_client_secret" {
  type        = string
  description = "GitLab OAuth application client secret"
  sensitive   = true
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

# it is supposed to have docker desktop with kubernetes enabled, so that grafana will be created and provider will be able to connect to it
provider "grafana" {
  url                  = "${var.grafana_scheme}://${var.grafana_hostname}"
  auth                 = "admin:${var.grafana_admin_password}"
  insecure_skip_verify = var.grafana_scheme == "http" # Skip TLS verification for HTTP, verify for HTTPS
}

# to run this example and have helm provider configured with existing k8s cluster set the following env: `export KUBE_CONFIG_PATH=/path/to/eks/cluster.kubeconfig`
provider "helm" {}
