# GitLab SSO Integration Test

This is a minimal test setup for GitLab OAuth2 SSO integration with Grafana.

## Prerequisites

1. A GitLab OAuth application must be created:
   - Go to GitLab → Profile → Preferences → Applications
   - Create a new OAuth application
   - Set the redirect URI to: `http://grafana.localhost/login/gitlab` and in new line `https://grafana.localhost/login/gitlab` (we need to enable both for local test only for live envs only https is enough)
   - Check openid, email, profile in the Scopes list. Leave the Confidential checkbox checked.
   - Copy the Application ID (client_id) and Secret (client_secret)

2. Kubernetes cluster with Helm and Grafana provider access

## Configuration

Set the GitLab OAuth credentials via environment variables or terraform.tfvars:

```bash
export TF_VAR_gitlab_client_id="your_gitlab_client_id"
export TF_VAR_gitlab_client_secret="your_gitlab_client_secret"
```

Or create a `terraform.tfvars` file:

```hcl
gitlab_client_id     = "your_gitlab_client_id"
gitlab_client_secret = "your_gitlab_client_secret"
```

## Usage

```bash
terraform init
terraform plan
terraform apply
```

## What This Test Includes

- Minimal Grafana deployment with database persistence
- GitLab OAuth2 SSO configuration
- No other stack components (Prometheus, Tempo, Loki disabled)
- No dashboards or alerts

## GitLab OAuth Application Setup

When creating the GitLab OAuth application, use the following redirect URI:
- **Redirect URI**: `https://grafana.example.com/login/gitlab`

Replace `grafana.example.com` with your actual Grafana ingress hostname.

## Testing the Integration

After applying the configuration:

1. Access Grafana at the configured ingress URL
2. You should see a "Sign in with GitLab" button on the login page
3. Click the button to authenticate via GitLab
4. After successful authentication, you'll be logged into Grafana

## Role Mapping

The example includes default role mapping configuration:

- **GitLab groups** → **Grafana roles**:
  - Users in `grafana-admin` group → **Admin** role
  - Users in `grafana-editor` group → **Editor** role
  - All other users → **Viewer** role (default)

To enable group-based role mapping:
1. Ensure your GitLab OAuth application has `read_api` scope (in addition to `api read_user`)
2. Create GitLab groups named `grafana-admin` and/or `grafana-editor` as needed
3. Add users to the appropriate groups in GitLab
4. Customize the `role_attribute_path` expression if you want different group names or mapping logic

The `role_attribute_path` uses JSONPath expressions to extract role information from the OAuth token. You can customize it based on your GitLab group structure.

## Notes

- This test uses minimal resources for quick validation
- The Grafana admin password is set to "admin" (change in production)
- For GitLab.com, the URLs are pre-configured. For self-hosted GitLab, update the `auth_url`, `token_url`, and `api_url` accordingly
- Role mapping requires GitLab groups to be accessible via the OAuth token. Ensure your OAuth application has appropriate scopes
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.3 |
| <a name="requirement_grafana"></a> [grafana](#requirement\_grafana) | ~> 4.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~> 2.17 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_this"></a> [this](#module\_this) | ../.. | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_gitlab_client_id"></a> [gitlab\_client\_id](#input\_gitlab\_client\_id) | GitLab OAuth application client ID | `string` | n/a | yes |
| <a name="input_gitlab_client_secret"></a> [gitlab\_client\_secret](#input\_gitlab\_client\_secret) | GitLab OAuth application client secret | `string` | n/a | yes |
| <a name="input_grafana_admin_password"></a> [grafana\_admin\_password](#input\_grafana\_admin\_password) | Grafana admin password | `string` | `"admin"` | no |
| <a name="input_grafana_hostname"></a> [grafana\_hostname](#input\_grafana\_hostname) | Grafana hostname for ingress and provider URL | `string` | `"grafana.localhost"` | no |
| <a name="input_grafana_scheme"></a> [grafana\_scheme](#input\_grafana\_scheme) | Grafana URL scheme (http or https) | `string` | `"http"` | no |

## Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
