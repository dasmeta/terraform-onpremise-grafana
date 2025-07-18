terraform {
  required_version = ">= 1.3.0"

  required_providers {
    grafana = {
      source  = "grafana/grafana"
      version = "~>3.21"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.17"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# there is need to have grafana running and available by provider url and auth
provider "grafana" {
  url  = "http://grafana.localhost"
  auth = "admin:admin"
}

provider "helm" {
}

provider "kubernetes" {
}

provider "aws" {
  region = "eu-central-1"
}
