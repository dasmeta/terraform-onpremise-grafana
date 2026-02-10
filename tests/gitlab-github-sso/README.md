# GitLab and GitHub SSO Integration Test

This is a minimal test setup demonstrating **multiple SSO providers** (GitLab and GitHub) configured simultaneously in Grafana.

## Prerequisites

1. **GitLab OAuth application** must be created:
   - Go to GitLab → Profile → Preferences → Applications
   - Create a new OAuth application
   - Set the redirect URI to: `https://grafana.localhost/login/gitlab`
   - Check openid, email, profile in the Scopes list. Leave the Confidential checkbox checked.
   - Copy the Application ID (client_id) and Secret (client_secret)

2. **GitHub OAuth application** must be created:
   - Go to GitHub → Settings → Developer settings → OAuth Apps
   - Create a new OAuth App
   - Set the Authorization callback URL to: `https:/grafana.localhost/login/github`
   - Copy the Client ID and Client Secret

3. Kubernetes cluster with Helm and Grafana provider access

## Configuration

Set the OAuth credentials via environment variables or terraform.tfvars:

```bash
# GitLab credentials
export TF_VAR_gitlab_client_id="your_gitlab_client_id"
export TF_VAR_gitlab_client_secret="your_gitlab_client_secret"

# GitHub credentials
export TF_VAR_github_client_id="your_github_client_id"
export TF_VAR_github_client_secret="your_github_client_secret"
```

Or create a `terraform.tfvars` file:

```hcl
gitlab_client_id     = "your_gitlab_client_id"
gitlab_client_secret = "your_gitlab_client_secret"
github_client_id     = "your_github_client_id"
github_client_secret = "your_github_client_secret"
```

## Usage

```bash
terraform init
terraform plan
terraform apply
```

## What This Test Includes

- Minimal Grafana deployment with database persistence
- **Both GitLab and GitHub OAuth2 SSO** configured simultaneously
- No other stack components (Prometheus, Tempo, Loki disabled)
- No dashboards or alerts

## OAuth Application Setup

### GitLab OAuth Application
- **Redirect URI**: `https://grafana.example.com/login/gitlab`
- Replace `grafana.example.com` with your actual Grafana ingress hostname

### GitHub OAuth Application
- **Authorization callback URL**: `https://grafana.example.com/login/github`
- Replace `grafana.example.com` with your actual Grafana ingress hostname

## Testing the Integration

After applying the configuration:

1. Access Grafana at the configured ingress URL
2. You should see **both** "Sign in with GitLab" and "Sign in with GitHub" buttons on the login page
3. Users can choose either provider to authenticate
4. After successful authentication, they'll be logged into Grafana

## Role Mapping

Both providers include default role mapping configuration:

### GitLab Role Mapping
- **GitLab groups** → **Grafana roles**:
  - Users in `grafana-admin` group → **Admin** role
  - Users in `grafana-editor` group → **Editor** role
  - All other users → **Viewer** role (default)

### GitHub Role Mapping
- **GitHub organizations/teams** → **Grafana roles**:
  - Users in `grafana-admin` org → **Admin** role
  - Users in `grafana-editor` org → **Editor** role
  - All other users → **Viewer** role (default)

To enable role mapping:
1. **GitLab**: The default scopes are `openid email profile`. To use group-based role mapping, add `read_api` scope: `openid email profile read_api`, then create groups named `grafana-admin` and/or `grafana-editor`
2. **GitHub**: Ensure your OAuth application has `read:org` scope and create organizations/teams as needed
3. Customize the `role_attribute_path` expression if you want different group/org names or mapping logic

The `role_attribute_path` uses JSONPath expressions to extract role information from the OAuth token. You can customize it based on your GitLab group or GitHub organization structure.

## Notes

- This test uses minimal resources for quick validation
- The Grafana admin password is set to "admin" (change in production)
- For GitLab.com/GitHub.com, the URLs are pre-configured. For self-hosted instances, update the `auth_url`, `token_url`, and `api_url` accordingly
- This example demonstrates that Grafana supports **multiple SSO providers** simultaneously, allowing users to choose their preferred authentication method
- Role mapping requires appropriate OAuth scopes and group/org access. Ensure your OAuth applications have the necessary permissions
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
| <a name="input_github_client_id"></a> [github\_client\_id](#input\_github\_client\_id) | GitHub OAuth application client ID | `string` | n/a | yes |
| <a name="input_github_client_secret"></a> [github\_client\_secret](#input\_github\_client\_secret) | GitHub OAuth application client secret | `string` | n/a | yes |
| <a name="input_gitlab_client_id"></a> [gitlab\_client\_id](#input\_gitlab\_client\_id) | GitLab OAuth application client ID | `string` | n/a | yes |
| <a name="input_gitlab_client_secret"></a> [gitlab\_client\_secret](#input\_gitlab\_client\_secret) | GitLab OAuth application client secret | `string` | n/a | yes |
| <a name="input_grafana_admin_password"></a> [grafana\_admin\_password](#input\_grafana\_admin\_password) | Grafana admin password | `string` | `"admin"` | no |
| <a name="input_grafana_hostname"></a> [grafana\_hostname](#input\_grafana\_hostname) | Grafana hostname for ingress and provider URL | `string` | `"grafana.localhost"` | no |
| <a name="input_grafana_scheme"></a> [grafana\_scheme](#input\_grafana\_scheme) | Grafana URL scheme (http or https) | `string` | `"http"` | no |

## Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
