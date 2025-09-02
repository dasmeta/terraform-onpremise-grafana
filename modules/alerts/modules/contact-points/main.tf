# Slack Integration
resource "grafana_contact_point" "slack_contact_point" {
  for_each = { for cp in var.slack_endpoints : cp.name => cp }

  name               = each.key
  disable_provenance = var.disable_provenance

  slack {
    endpoint_url            = each.value.webhook_url
    icon_emoji              = each.value.icon_emoji
    icon_url                = each.value.icon_url
    recipient               = each.value.webhook_url != null ? each.value.recipient : null
    text                    = each.value.text
    title                   = each.value.title
    token                   = each.value.webhook_url != null ? each.value.token : null
    url                     = each.value.webhook_url
    username                = each.value.username
    disable_resolve_message = each.value.disable_resolve_message
  }
}

# OpsGenie Integration
resource "grafana_contact_point" "opsgenie_contact_point" {
  for_each = { for cp in var.opsgenie_endpoints : cp.name => cp }

  name               = each.key
  disable_provenance = var.disable_provenance

  opsgenie {
    api_key                 = each.value.api_key
    auto_close              = each.value.auto_close
    message                 = each.value.message
    url                     = each.value.api_url
    disable_resolve_message = each.value.disable_resolve_message
  }
}

# MS Teams Integration
resource "grafana_contact_point" "teams_contact_point" {
  for_each = { for cp in var.teams_endpoints : cp.name => cp }

  name               = each.key
  disable_provenance = var.disable_provenance

  teams {
    title                   = each.value.title
    url                     = each.value.url
    message                 = each.value.message
    section_title           = each.value.section_title
    disable_resolve_message = each.value.disable_resolve_message
  }
}


# Webhook endpoints Integration
resource "grafana_contact_point" "webhook_contact_point" {
  for_each = { for cp in var.webhook_endpoints : cp.name => cp }

  name               = each.key
  disable_provenance = var.disable_provenance

  webhook {
    url                       = each.value.url
    authorization_credentials = each.value.authorization_credentials
    authorization_scheme      = each.value.authorization_scheme
    basic_auth_password       = each.value.basic_auth_password
    basic_auth_user           = each.value.basic_auth_user
    disable_resolve_message   = each.value.disable_resolve_message
    settings                  = each.value.settings
  }
}

resource "grafana_message_template" "body_template" {

  count    = var.enable_message_template ? 1 : 0
  name     = "Message Template"
  template = <<EOF
{{ define "default.message" }}
{{- $a := index .Alerts 0 -}}

{{- /* stable routing-ish context */ -}}
{{- $owner    := or (or .CommonAnnotations.owner    $a.Labels.owner)    "On-Call" -}}
{{- $provider := or (or .CommonAnnotations.provider $a.Labels.provider) "-" -}}
{{- $account  := or (or .CommonAnnotations.account  $a.Labels.account)  "-" -}}
{{- $env      := or .CommonLabels.env      $a.Labels.env      "-" -}}

{{- $currentFromB := "" -}}
{{- with (index $a.Values "B") -}}
  {{- $currentFromB = printf "%.0f" . -}}
{{- end -}}

{{- $metric     := or .CommonAnnotations.metric     $a.Annotations.metric -}}
{{- $threshold  := or .CommonAnnotations.threshold  $a.Annotations.threshold -}}
{{- $evaluation := or .CommonAnnotations.evaluation $a.Annotations.evaluation -}}
{{- $current    := or $currentFromB                 (or .CommonAnnotations.current $a.Annotations.current) -}}

{{- $summary := or .CommonAnnotations.summary $a.Annotations.summary -}}
{{- $impact  := or .CommonAnnotations.impact  $a.Annotations.impact  -}}

{{- $runbook := or .CommonAnnotations.runbook_url   $a.Annotations.runbook_url   -}}
{{- $dashURL := or .CommonAnnotations.dashboard_url $a.Annotations.dashboard_url -}}
{{- $logsURL := or .CommonAnnotations.logs_url      $a.Annotations.logs_url      -}}
{{- $silURL  := or .CommonAnnotations.silence_url   $a.Annotations.silence_url   -}}

📅 Date: {{ $a.StartsAt }}
📊 State: {{ .Status }}
👤 Owner: {{ $owner }}
🌍 Location: {{ $provider }}:{{ $account }}:{{ $env }}

📝 Description:
{{- if $summary }}
Summary: {{ $summary }}
{{- end }}
Detected breach on {{ or $metric "metric" }} (threshold: {{ or $threshold "n/a" }}, current: {{ or $current "n/a" }}).
Evaluation: {{ or $evaluation "n/a" }}. Affected component/resource are visible in the title.


⚠️ Impact:
{{- if $impact }}
{{ $impact }}
{{- else }}
Impact not provided. Please assess user/business effect (e.g., error rate, endpoints affected, replicas down).
{{- end }}

🔧 Next step: {{ if $runbook }}{{ $runbook }}{{ else }}Check logs and dashboards; follow service runbook.{{ end }}
🔗 Links: {{ if $dashURL }}[Dashboard]({{ $dashURL }}){{ else }}[Dashboard]{{ end }} {{ if $logsURL }}[Logs]({{ $logsURL }}){{ else }}[Logs]{{ end }} {{ if $silURL }}[Silence/Ack]({{ $silURL }}){{ else }}[Silence/Ack]{{ end }}

📡 Source: {{ or (or .CommonLabels.source $a.Labels.source) "Grafana" }}

--- Original ---
{{- if gt (len .Alerts.Firing) 0 -}}**Firing**
{{ template "__text_alert_list" .Alerts.Firing }}
{{ end -}}
{{- if gt (len .Alerts.Resolved) 0 -}}**Resolved**
{{ template "__text_alert_list" .Alerts.Resolved }}
{{ end -}}
{{ end }}
  EOF
}

resource "grafana_message_template" "title_template" {
  name     = "Title template"
  template = <<EOF
{{ define "default.title" }}
{{- $a := index .Alerts 0 -}}

{{- $prio := or (or .CommonLabels.priority $a.Labels.priority) "P3" -}}
{{- $issue := or (or .CommonAnnotations.issue_phrase $a.Annotations.issue_phrase) (or .CommonLabels.alertname $a.Labels.alertname) "Alert" -}}
{{- $val := printf "%.0f" (index $a.Values "B") -}}
{{- $threshold := or .CommonAnnotations.threshold $a.Labels.threshold }}
{{- $component := or .CommonAnnotations.component $a.Labels.component "unknown-component" -}}
{{- $resource  := or .CommonAnnotations.resource  $a.Labels.resource  "-" -}}
{{- $project   := or .CommonAnnotations.project   $a.Labels.project   "-" -}}

{{- template "prioIcon" $prio }} {{ $prio }}: {{ $issue }}{{ if and $val $threshold }} ({{ $val }} out of {{ $threshold }}){{ end }} on {{ $component }} / {{ $resource }} / {{ $project }}
{{ end }}

{{ define "prioIcon" }}
{{- $p := . -}}
{{- if or (eq $p "P1") (eq $p "p1") }}🛑
{{- else if or (eq $p "P2") (eq $p "p2") }}⚠️
{{- else if or (eq $p "P3") (eq $p "p3") }}❗
{{- else }}ℹ️{{ end -}}
{{ end }}
  EOF
}
