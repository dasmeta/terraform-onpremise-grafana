
variable "namespace" {
  type        = string
  description = "namespace to use for deployment"
  default     = "monitoring"
}

variable "create_namespace" {
  type        = bool
  description = "Whether create namespace if not exist"
  default     = true
}

variable "grafana_admin_password" {
  type        = string
  description = "admin password"
  default     = ""
}

variable "grafana_wait_duration" {
  type        = string
  description = "Duration to wait after Grafana deployment before applying datasources and SSO settings"
  default     = "10s"
}

variable "chart_version" {
  type        = string
  description = "grafana chart version"
  default     = "9.2.9"
}

variable "mysql_chart_version" {
  type        = string
  description = "mysql chart version"
  default     = "13.0.2"
}

variable "mysql_release_name" {
  type        = string
  description = "name of grafana mysql helm release"
  default     = "grafana-mysql"
}

variable "datasources" {
  type        = list(map(any))
  description = "A list of datasources configurations for grafana."
  default     = []
}

variable "release_name" {
  type        = string
  description = "grafana release name"
  default     = "grafana"
}

variable "configs" {
  type = object({
    resources = optional(object({
      requests = optional(object({
        cpu    = optional(string, "1")
        memory = optional(string, "2Gi")
      }), {})
      limits = optional(object({
        cpu    = optional(string, "2")
        memory = optional(string, "3Gi")
      }), {})
    }), {})
    database = optional(object({           # configure external(or in helm created) database base storing/persisting grafana data
      enabled       = optional(bool, true) # whether database based persistence is enabled
      create        = optional(bool, true) # whether to create mysql databases or use already existing database
      name          = optional(string, "grafana")
      type          = optional(string, "mysql") # when we set external database we can set any sql compatible one like postgresql or ms sql, but when we create database it supports only mysql and changing this field do not affect
      host          = optional(string, null)    # it will set right host for grafana mysql in case create=true
      user          = optional(string, "grafana")
      password      = optional(string, null)     # if not set it will use var.grafana_admin_password
      root_password = optional(string, null)     # if not set it will use var.grafana_admin_password
      persistence = optional(object({            # allows to configure created(when database.create=true) mysql databases storage/persistence configs
        enabled       = optional(bool, true)     # whether to have created in k8s mysql database with persistence
        size          = optional(string, "20Gi") # the size of primary persistent volume of mysql when creating it
        storage_class = optional(string, "")     # default storage class for the mysql database
      }), {})
      extra_flags = optional(string, "--skip-log-bin") # allows to set extra flags(whitespace separated) on grafana mysql primary instance, we have by default skip-log-bin flag set to disable bin-logs which overload mysql disc and/but we do not use multi replica mysql here

      # TODO: implement multi-replica/redundant grafana mysql database creation possibility
    }), {})
    persistence = optional(object({ # configure pvc base storing/persisting grafana data(it uses sqlite DB in this mode), NOTE: we use mysql database for data storage by default and no need to enable persistence if DB is set, so that we have persistence disable here by default
      enabled       = optional(bool, false)
      type          = optional(string, "pvc")
      size          = optional(string, "20Gi")
      storage_class = optional(string, "")
    }), {})
    ingress = optional(object({
      type        = optional(string, "nginx")
      public      = optional(bool, true)
      tls_enabled = optional(bool, true)

      annotations = optional(map(string), {})
      hosts       = optional(list(string), ["grafana.example.com"])
      path        = optional(string, "/")
      path_type   = optional(string, "Prefix")
    }), {})

    service_account = optional(object({
      name        = optional(string, "grafana")
      enable      = optional(bool, true)
      annotations = optional(map(string), {})
    }), {})

    redundancy = optional(object({
      enabled                  = optional(bool, false)
      max_replicas             = optional(number, 4)
      min_replicas             = optional(number, 1)
      redundancy_storage_class = optional(string, "")
    }), {})

    trace_log_mapping = optional(object({
      enabled       = optional(bool, false)
      trace_pattern = optional(string, "trace_id=(\\w+)")
    }), {})
    replicas  = optional(number, 1)
    image_tag = optional(string, "11.4.2")
  })

  description = "Values to construct the values file for Grafana Helm chart"
  default     = {}
}

variable "extra_configs" {
  type        = any
  default     = {}
  description = "Allows to pass extra/custom configs to grafana helm chart, this configs will deep-merged with all generated internal configs and can override the default set ones. All available options can be found in for the specified chart version here: https://artifacthub.io/packages/helm/grafana/grafana?modal=values"
}

variable "mysql_extra_configs" {
  type        = any
  default     = {}
  description = "Allows to pass extra/custom configs to grafana-mysql created helm chart, this configs will deep-merged with all generated internal configs and can override the default set ones. All available options can be found in for the specified chart version here: https://artifacthub.io/packages/helm/bitnami/mysql?modal=values"
}

variable "sso_settings" {
  type = map(object({
    oauth2_settings = optional(object({
      name                       = string                # Display name shown on the login page as "Sign in with...". This is different from the provider name (which is the map key like "gitlab", "github", "google", "azuread", "okta", "generic_oauth", "saml", "ldap"). The provider name determines the OAuth2 endpoints, while this name is just the label shown to users (e.g., "GitLab", "GitHub", "Company SSO")
      client_id                  = string                # The client ID of your OAuth2 application
      client_secret              = string                # The client secret of your OAuth2 application
      auth_url                   = optional(string)      # OAuth2 authorization URL (not needed for built-in providers: gitlab, github, google, azuread, okta)
      token_url                  = optional(string)      # OAuth2 token URL (not needed for built-in providers: gitlab, github, google, azuread, okta)
      api_url                    = optional(string)      # OAuth2 API URL (not needed for built-in providers: gitlab, github, google, azuread, okta)
      allow_sign_up              = optional(bool, true)  # If true, new users can automatically create Grafana accounts on first login
      auto_login                 = optional(bool, false) # If true, automatically logs in users, skipping the login screen
      scopes                     = optional(string)      # Comma or space-separated list of OAuth2 scopes (e.g., "openid email profile" for GitLab)
      allowed_groups             = optional(string)      # Comma or space-separated list of GitLab group names (e.g., "org-1", "org-2", "dev-team"). In GitLab, "group" is the organizational unit (like "organization" in GitHub). User must be a MEMBER of at least one of these groups to log in. This checks GROUP MEMBERSHIP, NOT the user's role within the group (Maintainer/Developer/Guest). For GitHub: organization names. Requires OAuth scope "read_api" for GitLab or "read:org" for GitHub.
      allowed_domains            = optional(string)      # Comma or space-separated list of email domains. User must belong to at least one domain to log in. For GitHub: requires "user:email" scope and the user's email must be verified in GitHub. Email privacy settings in GitHub may prevent this from working.
      role_attribute_path        = optional(string)      # JSONPath expression to map OAuth provider groups to Grafana roles. Checks if user is a member of SPECIFIC groups (not org names). Example: "contains(groups[*], 'grafana-admin') && 'Admin' || contains(groups[*], 'grafana-editor') && 'Editor' || 'Viewer'" means: if user is in "grafana-admin" group → Admin role, if in "grafana-editor" group → Editor role, otherwise → Viewer. These groups (e.g., "grafana-admin", "grafana-editor") must exist in your GitLab/GitHub and users must be added to them. Different from allowed_groups which checks org membership.
      role_attribute_strict      = optional(bool)        # If true, requires role_attribute_path to be set and valid
      allow_assign_grafana_admin = optional(bool)        # If true, allows assigning Grafana Admin role via OAuth
      skip_org_role_sync         = optional(bool)        # If true, skips syncing organization roles from OAuth
    }))
    saml_settings = optional(object({
      name             = string                # Display name shown on the login page as "Sign in with..."
      idp_metadata_url = optional(string)      # URL to the SAML Identity Provider metadata XML file
      allow_sign_up    = optional(bool, true)  # If true, new users can automatically create Grafana accounts on first login
      auto_login       = optional(bool, false) # If true, automatically logs in users, skipping the login screen
    }))
    ldap_settings = optional(object({
      allow_sign_up = optional(bool, true) # If true, new users can automatically create Grafana accounts on first login
      config = object({
        servers = list(object({
          host            = string                # LDAP server hostname or IP address
          port            = optional(number, 389) # LDAP server port (default: 389 for LDAP, 636 for LDAPS)
          search_base_dns = list(string)          # Base DNs to search for users (e.g., ["ou=users,dc=example,dc=com"])
          search_filter   = string                # LDAP search filter to find users (e.g., "(cn=%s)" or "(uid=%s)")
        }))
      })
    }))
  }))
  default     = {}
  description = "SSO settings for Grafana. Supports OAuth2 providers (gitlab, github, google, azuread, okta, generic_oauth), SAML, and LDAP. The map key should be the provider name (e.g., 'gitlab', 'github', 'saml', 'ldap')."
  sensitive   = true
}
