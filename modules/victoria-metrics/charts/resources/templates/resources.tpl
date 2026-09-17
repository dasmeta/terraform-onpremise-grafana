{{- range .Values.objects }}
---
{{ toYaml . }}
{{- end }}
