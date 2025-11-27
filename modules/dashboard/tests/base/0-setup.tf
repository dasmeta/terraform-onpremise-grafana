terraform {
  required_version = "~> 1.3"

  required_providers {
    grafana = {
      source  = "grafana/grafana"
      version = "~> 4.0"
    }
  }
}

# you can start dev grafana server locally using `docker compose up -d` from `/tests` folder before running the test locally
provider "grafana" {
  url  = "https://grafana.example.com"
  auth = "admin:admin"
}
