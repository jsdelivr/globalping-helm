{{/*
Expand the name of the chart.
*/}}
{{- define "globalping-probe.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "globalping-probe.fullname" -}}
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
Create chart name and version as used by the chart label.
*/}}
{{- define "globalping-probe.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "globalping-probe.labels" -}}
helm.sh/chart: {{ include "globalping-probe.chart" . }}
{{ include "globalping-probe.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "globalping-probe.selectorLabels" -}}
app.kubernetes.io/name: {{ include "globalping-probe.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "globalping-probe.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "globalping-probe.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Image name
*/}}
{{- define "globalping-probe.image" -}}
{{- $tag := .Values.image.tag | default .Chart.AppVersion | default "latest" }}
{{- printf "%s:%s" .Values.image.repository $tag }}
{{- end }}

{{/*
Validate required values
*/}}
{{- define "globalping-probe.validateValues" -}}
{{- if not .Values.globalpingToken }}
{{- fail "ERROR: globalpingToken is required. Please provide a valid Globalping adoption token." }}
{{- end }}
{{- end }}

