terraform {
  required_version = ">= 1.3.0"

  required_providers {

    grafana = {
      source  = "grafana/grafana"
      version = "~> 4.0"
    }

    random = {
      source  = "hashicorp/random"
      version = ">= 3.6.2"
    }
  }
}
