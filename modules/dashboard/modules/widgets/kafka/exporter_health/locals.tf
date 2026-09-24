module "selector" {
  source = "../selector"

  namespace     = var.namespace
  extra_filters = var.extra_filters
  cluster_label = var.cluster_label
  cluster       = var.cluster
}

locals {
  selector = module.selector.selector
}
