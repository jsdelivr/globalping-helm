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
Pod template metadata shared by workload resources.
*/}}
{{- define "globalping-probe.podMetadata" -}}
{{- $ctx := .ctx }}
{{- $annotations := dict }}
{{- if $ctx.Values.globalpingToken }}
{{- $_ := set $annotations "checksum/secret" (include "globalping-probe.secret" $ctx | sha256sum) }}
{{- end }}
{{- range $key, $value := $ctx.Values.podAnnotations }}
{{- $_ := set $annotations $key $value }}
{{- end }}
labels:
  {{- include "globalping-probe.labels" $ctx | nindent 2 }}
  {{- with $ctx.Values.podLabels }}
  {{- toYaml . | nindent 2 }}
  {{- end }}
{{- if gt (len $annotations) 0 }}
annotations:
  {{- toYaml $annotations | nindent 2 }}
{{- end }}
{{- end }}

{{/*
Shared pod spec for the Globalping probe containers.
*/}}
{{- define "globalping-probe.podSpec" -}}
{{- $ctx := . }}
serviceAccountName: {{ include "globalping-probe.serviceAccountName" $ctx }}
{{- with $ctx.Values.imagePullSecrets }}
imagePullSecrets:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with $ctx.Values.podSecurityContext }}
securityContext:
  {{- toYaml . | nindent 2 }}
{{- end }}
hostNetwork: {{ $ctx.Values.network.hostNetwork }}
dnsPolicy: {{ $ctx.Values.network.dnsPolicy }}
containers:
  - name: {{ $ctx.Chart.Name }}
    image: {{ include "globalping-probe.image" $ctx }}
    imagePullPolicy: {{ $ctx.Values.image.pullPolicy }}
    {{- with $ctx.Values.securityContext }}
    securityContext:
      {{- toYaml . | nindent 6 }}
    {{- end }}
    env:
      {{- if $ctx.Values.globalpingToken }}
      - name: GP_ADOPTION_TOKEN
        valueFrom:
          secretKeyRef:
            name: {{ include "globalping-probe.fullname" $ctx }}
            key: gp-adoption-token
      {{- end }}
      {{- if $ctx.Values.env.debug }}
      - name: DEBUG
        value: "globalping-probe:*"
      {{- end }}
      - name: LOG_FORMAT
        value: {{ default "text" $ctx.Values.env.logFormat | quote }}
      {{- range $item := $ctx.Values.env.extra }}
      - name: {{ required "env.extra items must define a name" $item.name }}
        {{- if $item.valueFrom }}
        valueFrom:
          {{- toYaml $item.valueFrom | nindent 10 }}
        {{- else }}
        value: {{ required (printf "env.extra item %s must define value or valueFrom" $item.name) $item.value | quote }}
        {{- end }}
      {{- end }}
    {{- with $ctx.Values.resources }}
    resources:
      {{- toYaml . | nindent 6 }}
    {{- end }}
    {{- if $ctx.Values.livenessProbe.enabled }}
    livenessProbe:
      exec:
        command:
          {{- toYaml $ctx.Values.livenessProbe.exec.command | nindent 10 }}
      initialDelaySeconds: {{ $ctx.Values.livenessProbe.initialDelaySeconds }}
      periodSeconds: {{ $ctx.Values.livenessProbe.periodSeconds }}
      timeoutSeconds: {{ $ctx.Values.livenessProbe.timeoutSeconds }}
      successThreshold: {{ $ctx.Values.livenessProbe.successThreshold }}
      failureThreshold: {{ $ctx.Values.livenessProbe.failureThreshold }}
    {{- end }}
    {{- if $ctx.Values.readinessProbe.enabled }}
    readinessProbe:
      exec:
        command:
          {{- toYaml $ctx.Values.readinessProbe.exec.command | nindent 10 }}
      initialDelaySeconds: {{ $ctx.Values.readinessProbe.initialDelaySeconds }}
      periodSeconds: {{ $ctx.Values.readinessProbe.periodSeconds }}
      timeoutSeconds: {{ $ctx.Values.readinessProbe.timeoutSeconds }}
      successThreshold: {{ $ctx.Values.readinessProbe.successThreshold }}
      failureThreshold: {{ $ctx.Values.readinessProbe.failureThreshold }}
    {{- end }}
    {{- if $ctx.Values.persistence.enabled }}
    volumeMounts:
      - name: probe-data
        mountPath: /app/.cache
    {{- end }}
{{- if $ctx.Values.persistence.enabled }}
volumes:
  - name: probe-data
    persistentVolumeClaim:
      claimName: {{ include "globalping-probe.fullname" $ctx }}
{{- end }}
{{- with $ctx.Values.nodeSelector }}
nodeSelector:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with $ctx.Values.affinity }}
affinity:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with $ctx.Values.tolerations }}
tolerations:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- end }}

