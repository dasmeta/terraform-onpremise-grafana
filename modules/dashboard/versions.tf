terraform {
  required_version = ">= 1.8.0"

  required_providers {

    grafana = {
      source  = "grafana/grafana"
      version = "~> 4.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
    deepmerge = {
      source  = "isometry/deepmerge"
      version = "1.0.2"
    }
  }
}
