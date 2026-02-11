module "this" {
  source = "../.."

  # Minimal Grafana setup with GitLab SSO integration
  grafana = {
    enabled = true
    resources = {
      requests = {
        cpu    = "1"
        memory = "1Gi"
      }
    }
    ingress = {
      type        = "nginx"
      tls_enabled = false # Set to false for local testing without TLS certificates
      public      = true
      hosts       = [var.grafana_hostname]
      annotations = {}
    }
    database = {
      enabled = true
      create  = true
    }
    persistence = {
      enabled = false
    }
    # GitLab OAuth2 SSO configuration with role mapping
    sso_settings = {
      gitlab = {
        oauth2_settings = {
          name          = "GitLab"
          client_id     = var.gitlab_client_id     # Set via TF_VAR_gitlab_client_id or terraform.tfvars
          client_secret = var.gitlab_client_secret # Set via TF_VAR_gitlab_client_secret or terraform.tfvars
          # Note: auth_url, token_url, and api_url are not needed for built-in GitLab provider
          # Grafana automatically uses the correct URLs for gitlab.com
          # For self-hosted GitLab, use generic_oauth provider instead
          allow_sign_up   = true
          allowed_groups  = "dasmeta-customers" # use this if you want to restrict access to specific groups
          allowed_domains = "dasmeta.com"
          auto_login      = false
          scopes          = "openid email profile"
          # Role mapping: Maps GitLab groups to Grafana roles
          # Default mapping: users in 'grafana-admin' group -> Admin, 'grafana-editor' group -> Editor, others -> Viewer
          # Note: To use groups for role mapping, you may need to add 'read_api' scope: "openid email profile read_api"
          role_attribute_path        = "contains(groups[*], 'grafana-admin') && 'Admin' || contains(groups[*], 'grafana-editor') && 'Editor' || 'Viewer'"
          role_attribute_strict      = false # Set to true to require role mapping, false allows default Viewer role
          allow_assign_grafana_admin = true  # Allow assigning Grafana Admin role via OAuth
          skip_org_role_sync         = false # Sync organization roles from OAuth
        }
      }
    }
  }

  # Disable other stack components
  prometheus = {
    enabled = false
  }

  tempo = {
    enabled = false
  }

  loki_stack = {
    enabled = false
  }

  # No dashboards
  application_dashboard          = []
  alerts                         = {}
  dashboards_json_files          = []
  deploy_grafana_stack_dashboard = false

  grafana_admin_password = var.grafana_admin_password
}
