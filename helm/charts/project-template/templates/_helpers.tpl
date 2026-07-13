{{/* Name of the project namespace */}}
{{- define "project-template.namespace" -}}
{{- required "A vaid namespace is required" .Values.namespace -}}
{{- end }}

{{/* Name of the project */}}
{{- define "project-template.project" -}}
{{- required "A valid project name is required" .Values.project -}}
{{- end }}

{{/* Name of the client */}}
{{- define "project-template.client" -}}
{{- required "A valid client name is required" .Values.client -}}
{{- end }}
