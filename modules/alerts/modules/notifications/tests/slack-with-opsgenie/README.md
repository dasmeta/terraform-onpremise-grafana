## Slack with Opsgenie
This example creates a default notification policy for the Slack contact point, which includes a nested policy for the Opsgenie contact point.

Alerts with the label `priority = P1` will be sent to Opsgenie, while all other alerts will be sent to Slack.
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_grafana"></a> [grafana](#requirement\_grafana) | >= 3.7.0 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_opsgenie_contact_points"></a> [opsgenie\_contact\_points](#module\_opsgenie\_contact\_points) | ../../../alert-contact-points/tests/opsgenie | n/a |
| <a name="module_slack_contact_points"></a> [slack\_contact\_points](#module\_slack\_contact\_points) | ../../../alert-contact-points/tests/slack | n/a |
| <a name="module_this"></a> [this](#module\_this) | ../../ | n/a |

## Resources

No resources.

## Inputs

No inputs.

## Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
