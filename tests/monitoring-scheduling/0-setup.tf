terraform {
  required_version = ">= 1.7, < 2.0"

  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.17"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7"
    }
    deepmerge = {
      source  = "isometry/deepmerge"
      version = "~> 1.1"
    }
  }
}
