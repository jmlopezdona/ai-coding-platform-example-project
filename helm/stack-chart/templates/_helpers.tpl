{{/*
===========================================================================
  stack-chart — Template helpers
===========================================================================
*/}}

{{/*
Chart name, truncated to 63 characters.
*/}}
{{- define "stack-chart.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Fully qualified app name.
Uses release name combined with chart name, truncated to 63 characters.
*/}}
{{- define "stack-chart.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Chart label value (name + version).
*/}}
{{- define "stack-chart.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels applied to every resource.
*/}}
{{- define "stack-chart.labels" -}}
helm.sh/chart: {{ include "stack-chart.chart" . }}
{{ include "stack-chart.selectorLabels" . }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
platform.internal/env-id: {{ .Values.global.envId | quote }}
platform.internal/branch: {{ .Values.global.branch | replace "/" "--" | quote }}
{{- end }}

{{/*
Selector labels used in Deployment/Service matchLabels.
*/}}
{{- define "stack-chart.selectorLabels" -}}
app.kubernetes.io/name: {{ include "stack-chart.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Component-specific selector labels.
Usage: {{ include "stack-chart.componentLabels" (dict "component" "backend" "root" .) }}
*/}}
{{- define "stack-chart.componentLabels" -}}
app.kubernetes.io/name: {{ include "stack-chart.name" .root }}
app.kubernetes.io/instance: {{ .root.Release.Name }}
app.kubernetes.io/component: {{ .component }}
{{- end }}

{{/*
Resolve an image reference.
If the image contains a "/" it is used as-is; otherwise it is prefixed with global.registry.
Tag defaults to global.branch.
Usage: {{ include "stack-chart.image" (dict "image" .Values.frontend.image "root" .) }}
*/}}
{{- define "stack-chart.image" -}}
{{- $img := .image -}}
{{- if not (contains "/" $img) -}}
{{- $img = printf "%s/%s" .root.Values.global.registry $img -}}
{{- end -}}
{{- if contains ":" $img -}}
{{- $img -}}
{{- else -}}
{{- printf "%s:%s" $img .root.Values.global.branch -}}
{{- end -}}
{{- end }}
