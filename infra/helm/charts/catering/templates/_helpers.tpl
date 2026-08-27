{{- define "catering.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "catering.fullname" -}}
{{- printf "%s-%s" .Release.Name (include "catering.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "catering.labels" -}}
app.kubernetes.io/name: {{ include "catering.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: burritoworks-platform
{{- end -}}

{{- define "catering.selectorLabels" -}}
app.kubernetes.io/name: {{ include "catering.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}
