terraform {
  required_version = "~> 1.3"

  required_providers {
    grafana = {
      source  = "grafana/grafana"
      version = "~> 4.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.4"
    }
  }
}
