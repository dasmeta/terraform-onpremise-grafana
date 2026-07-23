module "loki_simple_scalable" {
  source = "../../modules/loki-stack"

  namespace = var.namespace
  configs = {
    loki = {
      deploymentMode = "SimpleScalable"
      release_name   = "loki"
      storage = {
        type = "s3"
        s3 = {
          endpoint = "s3.amazonaws.com"
          region   = "us-east-1"
          bucketnames = {
            chunks = "loki-chunks"
            ruler  = "loki-ruler"
            admin  = "loki-admin"
          }
        }
      }
      schemaConfig = [{
        from         = "2025-01-01"
        object_store = "filesystem"
        store        = "tsdb"
        schema       = "v13"
      }]
      compactor_options = {
        delete_request_store = "filesystem"
      }
      write = {
        replicas = 3
      }
    }
    promtail = {
      enabled = true
    }
  }
}

module "loki_single_binary" {
  source = "../../modules/loki-stack"

  namespace = var.namespace
  configs = {
    loki = {
      deploymentMode = "SingleBinary"
      release_name   = "loki-sb"
    }
    promtail = {
      enabled = false
    }
  }
}

output "simple_scalable_query_url" {
  value = module.loki_simple_scalable.query_url
}

output "simple_scalable_push_url" {
  value = module.loki_simple_scalable.push_url
}

output "simple_scalable_deployment_mode" {
  value = module.loki_simple_scalable.deployment_mode
}

output "single_binary_query_url" {
  value = module.loki_single_binary.query_url
}

output "single_binary_push_url" {
  value = module.loki_single_binary.push_url
}

output "single_binary_deployment_mode" {
  value = module.loki_single_binary.deployment_mode
}
