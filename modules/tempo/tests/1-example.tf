module "tempo" {
  source = "../."

  configs = {
    enabled           = true
    storage_backend   = "s3"
    bucket_name       = "my-tempo-traces-kauwnw"
    oidc_provider_arn = "eks-oidc-provider-arn"
    tempo_role_arn    = "arn:aws:iam::12345678912:role/tempo-s3-access-manual"

    enable_metrics_generator = true
    enable_service_monitor   = true

    persistence = {
      enabled       = true
      size          = "10Gi"
      storage_class = "gp2"
    }
  }

}
