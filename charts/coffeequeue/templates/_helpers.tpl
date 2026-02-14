{{- define "coffeequeue.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "coffeequeue.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := include "coffeequeue.name" . -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{- define "coffeequeue.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" -}}
{{- end -}}

{{- define "coffeequeue.labels" -}}
helm.sh/chart: {{ include "coffeequeue.chart" . }}
app.kubernetes.io/name: {{ include "coffeequeue.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{- define "coffeequeue.appName" -}}
{{- printf "%s-app" (include "coffeequeue.fullname" .) -}}
{{- end -}}

{{- define "coffeequeue.postgresName" -}}
{{- printf "%s-postgres" (include "coffeequeue.fullname" .) -}}
{{- end -}}

{{- define "coffeequeue.postgresConfigName" -}}
{{- printf "%s-init" (include "coffeequeue.postgresName" .) -}}
{{- end -}}

{{- define "coffeequeue.postgresServiceName" -}}
{{- include "coffeequeue.postgresName" . -}}
{{- end -}}

{{- define "coffeequeue.appSelectorLabels" -}}
app.kubernetes.io/name: {{ include "coffeequeue.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: app
{{- end -}}

{{- define "coffeequeue.postgresSelectorLabels" -}}
app.kubernetes.io/name: {{ include "coffeequeue.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: postgres
{{- end -}}
