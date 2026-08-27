{{- define "order-ahead.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "order-ahead.fullname" -}}
{{- printf "%s-%s" .Release.Name (include "order-ahead.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "order-ahead.labels" -}}
app.kubernetes.io/name: {{ include "order-ahead.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: burritoworks-platform
{{- end -}}

{{- define "order-ahead.selectorLabels" -}}
app.kubernetes.io/name: {{ include "order-ahead.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}
