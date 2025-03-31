module "tempo" {
  source = "../."
  region = "us-east-2"

  configs = {
    enabled           = true
    storage_backend   = "s3"
    bucket_name       = "my-tempo-traces-kauwnw"
    oidc_provider_arn = "eks-oidc-provider-arn"

    enable_metrics_generator = true
    enable_service_monitor   = true

    persistence = {
      enabled       = true
      size          = "10Gi"
      storage_class = "gp2"
    }

    ingress = {
      enabled = true
      annotations = {
        "kubernetes.io/ingress.class"                = "nginx"
        "nginx.ingress.kubernetes.io/rewrite-target" = "/"
        "nginx.ingress.kubernetes.io/ssl-redirect"   = "true"
      }
      hosts     = ["tempo.example.com"]
      path      = "/"
      path_type = "Prefix"
    }
  }

}
