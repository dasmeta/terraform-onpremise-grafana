terraform {
  required_version = ">= 1.3.0"

  required_providers {
    grafana = {
      source  = "grafana/grafana"
      version = ">= 3.7.0"
    }
  }
}

# you can start dev grafana server locally using `docker compose up -d` from `/tests` folder before running the test locally
provider "grafana" {
  url  = "http://localhost:3000"
  auth = "admin:admin"
}
