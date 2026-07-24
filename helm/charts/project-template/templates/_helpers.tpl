{{/* Name of the project namespace */}}
{{- define "project-template.namespace" -}}
{{- required "A valid namespace is required" .Values.namespace -}}
{{- end }}

{{/* Name of the project */}}
{{- define "project-template.project" -}}
{{- required "A valid project name is required" .Values.project -}}
{{- end }}

{{/* Name of the tenant */}}
{{- define "project-template.tenant" -}}
{{- required "A valid tenant name is required" .Values.tenant -}}
{{- end }}

{{/* Name of the environment */}}
{{- define "project-template.environment" -}}
{{- required "A valid environment name is required" .Values.environment -}}
{{- end }}
