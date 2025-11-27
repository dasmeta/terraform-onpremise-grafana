terraform {
  required_version = "~> 1.3"
  required_providers {
    helm = "~> 2.0"
    kubernetes = {
      version = "~>2.3"
    }
  }
}
