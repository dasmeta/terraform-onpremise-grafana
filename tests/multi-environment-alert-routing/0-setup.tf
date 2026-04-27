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

variable "slack_webhook_url" {
  type        = string
  description = "Slack webhook URL"
  default     = "https://hooks.slack.com/services/xxxxx/yyyyyy/zzzzzzzzzzzz" # to customize set env: `export TF_VAR_slack_webhook_url=https://hooks.slack.com/services/<workspace_id>/<channel_id>/<webhook_id>`
}

variable "environments" {
  type        = list(string)
  description = "Environments to deploy http-echo app to"
  default     = ["dev", "stage", "prod"]
}

# it is supposed to have docker desktop with kubernetes enabled, so that grafana will be created and provider will be able to connect to it
provider "grafana" {
  url                  = "${var.grafana_scheme}://${var.grafana_hostname}"
  auth                 = "admin:${var.grafana_admin_password}"
  insecure_skip_verify = var.grafana_scheme == "http" # Skip TLS verification for HTTP, verify for HTTPS
}

# to run this example and have helm provider configured with existing k8s cluster set the following env: `export KUBE_CONFIG_PATH=/path/to/eks/cluster.kubeconfig`
provider "helm" {}


# we deploy same app in two different namespaces: dev, stage, prod to check multi env alert routing
resource "helm_release" "http_echo" {
  for_each = toset(var.environments)

  name             = "http-echo"
  repository       = "https://dasmeta.github.io/helm"
  chart            = "base"
  namespace        = each.value
  create_namespace = true
  version          = "0.3.28"
  wait             = true

  values = [
    file("${path.module}/http-echo.yaml"),
    <<-EOT
    ingress:
      hosts:
        - host: http-echo.localhost
          paths:
            - path: "/${each.value}"
    EOT
  ]
}
