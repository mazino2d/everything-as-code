{{/*
Validates that workload is one of the recognised types.
Call from any template to surface a clear error on misconfiguration.
*/}}
{{- define "eac-app.validateWorkload" -}}
{{- $valid := list "deployment" "statefulset" -}}
{{- if not (has .Values.workload $valid) -}}
{{- fail (printf "workload must be one of: deployment, statefulset — got %q" .Values.workload) -}}
{{- end -}}
{{- end -}}

{{/*
Pod template metadata (inside metadata: of the pod template).
Shared between Deployment, Argo Rollout and StatefulSet templates.
*/}}
{{- define "eac-app.podMetadata" -}}
labels:
  app: {{ .Values.name }}
  # Alloy derives the Loki `app` label from this one.
  app.kubernetes.io/name: {{ .Values.name }}
  {{- if .Values.podLabels }}
  {{- toYaml .Values.podLabels | nindent 2 }}
  {{- end }}
{{- if or .Values.podAnnotations .Values.instrumentation.enabled }}
annotations:
  {{- if .Values.podAnnotations }}
  {{- toYaml .Values.podAnnotations | nindent 2 }}
  {{- end }}
  {{- if .Values.instrumentation.enabled }}
  instrumentation.opentelemetry.io/inject-python: {{ .Values.name }}
  {{- end }}
{{- end }}
{{- end }}

{{/*
Service ports (inside spec.ports: of a Service).
Shared between the main, preview and headless Services; only the main one
passes nodePort: true.
Usage: include "eac-app.servicePorts" (dict "Values" .Values "nodePort" true)
*/}}
{{- define "eac-app.servicePorts" -}}
{{- $withNodePort := .nodePort }}
{{- range .Values.service.ports }}
- port: {{ .port }}
  targetPort: {{ .containerPort }}
  protocol: TCP
  {{- if .name }}
  name: {{ .name }}
  {{- end }}
  {{- if and $withNodePort .nodePort }}
  nodePort: {{ .nodePort }}
  {{- end }}
{{- end }}
{{- end }}

{{/*
Pod spec contents (inside spec: of the pod template).
Shared between Deployment, Argo Rollout and StatefulSet templates.
*/}}
{{- define "eac-app.podSpec" -}}
{{- if .Values.serviceAccountName }}
serviceAccountName: {{ .Values.serviceAccountName }}
{{- end }}
{{- with .Values.podSecurityContext }}
securityContext:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- if .Values.dnsConfig }}
dnsPolicy: None
dnsConfig:
  {{- toYaml .Values.dnsConfig | nindent 2 }}
{{- end }}
containers:
  - name: {{ .Values.name }}
    image: {{ .Values.image.repository }}:{{ .Values.image.tag }}
    {{- if .Values.command }}
    command: {{ toYaml .Values.command | nindent 6 }}
    {{- end }}
    {{- if .Values.args }}
    args: {{ toYaml .Values.args | nindent 6 }}
    {{- end }}
    {{- $parsedSecretEnvEntries := dict "items" (list) }}
    {{- $secretEnvFromRefs := dict "enabled" false }}
    {{- range .Values.secrets }}
    {{- if and (kindIs "string" .) (contains "=" .) }}
    {{- $parts := splitList "=" . }}
      {{- if lt (len $parts) 2 }}
    {{- fail (printf "invalid secrets entry %q: expected ENV_NAME=secretName:key" .) }}
    {{- end }}
    {{- $envName := trim (index $parts 0) }}
    {{- if eq $envName "" }}
    {{- fail (printf "invalid secrets entry %q: empty ENV_NAME" .) }}
    {{- end }}
      {{- $envValue := trim (join "=" (slice $parts 1)) }}
    {{- $mappingParts := splitList ":" $envValue }}
    {{- if and (eq (len $mappingParts) 2) (ne (trim (index $mappingParts 0)) "") (ne (trim (index $mappingParts 1)) "") }}
    {{- $_ := set $parsedSecretEnvEntries "items" (append (index $parsedSecretEnvEntries "items") (dict "name" $envName "secretName" (trim (index $mappingParts 0)) "key" (trim (index $mappingParts 1)))) }}
    {{- else }}
    {{- fail (printf "invalid secrets entry %q: expected ENV_NAME=secretName:key — for plain config use env:" .) }}
    {{- end }}
    {{- else if and (kindIs "string" .) . }}
    {{- $_ := set $secretEnvFromRefs "enabled" true }}
    {{- end }}
    {{- end }}
    ports:
      {{- range .Values.service.ports }}
      - containerPort: {{ .containerPort }}
        protocol: TCP
        {{- if .name }}
        name: {{ .name }}
        {{- end }}
      {{- end }}
    {{- if or .Values.env (gt (len (index $parsedSecretEnvEntries "items")) 0) }}
    env:
      {{- range (index $parsedSecretEnvEntries "items") }}
      - name: {{ .name }}
        valueFrom:
          secretKeyRef:
            name: {{ .secretName }}
            key: {{ .key }}
      {{- end }}
      {{- range $k, $v := .Values.env }}
      - name: {{ $k }}
        value: {{ $v | quote }}
      {{- end }}
    {{- end }}
    {{- if or .Values.env (index $secretEnvFromRefs "enabled") }}
    envFrom:
      {{- if .Values.env }}
      - configMapRef:
          name: {{ .Values.name }}
      {{- end }}
      {{- range .Values.secrets }}
      {{- if not (contains "=" .) }}
      - secretRef:
          name: {{ . }}
      {{- end }}
      {{- end }}
    {{- end }}
    {{- if and (eq .Values.workload "statefulset") .Values.statefulset.storage.enabled }}
    volumeMounts:
      - name: data
        mountPath: {{ .Values.statefulset.storage.mountPath }}
    {{- end }}
    resources:
      {{- toYaml .Values.resources | nindent 6 }}
{{- end }}
