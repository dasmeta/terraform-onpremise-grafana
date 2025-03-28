module "tempo" {
  source = "../."
  region = "us-east-2"

  configs = {
    storage_backend = "s3"
    bucket_name     = "my-tempo-traces"

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
        "kubernetes.io/ingress.class"                = "alb"
        "alb.ingress.kubernetes.io/scheme"           = "internet-facing"
        "alb.ingress.kubernetes.io/target-type"      = "ip"
        "alb.ingress.kubernetes.io/listen-ports"     = "[{\\\"HTTP\\\": 80}, {\\\"HTTPS\\\":443}]"
        "alb.ingress.kubernetes.io/group.name"       = "dev-ingress"
        "alb.ingress.kubernetes.io/healthcheck-path" = "/"
        "alb.ingress.kubernetes.io/healthcheck-path" = "/api/health"
        "alb.ingress.kubernetes.io/ssl-redirect"     = "443"
        "alb.ingress.kubernetes.io/certificate-arn"  = "certificate_arn"
      }
      hosts     = ["tempo.dev.trysela.com"]
      path      = "/"
      path_type = "Prefix"
    }
  }
}
