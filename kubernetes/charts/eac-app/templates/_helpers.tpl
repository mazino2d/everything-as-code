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
Pod spec contents (inside spec: of the pod template).
Shared between Deployment and Argo Rollout templates.
*/}}
{{- define "eac-app.podSpec" -}}
{{- if .Values.serviceAccountName }}
serviceAccountName: {{ .Values.serviceAccountName }}
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
      {{- range $k, $v := .Values.env }}
      - name: {{ $k }}
        value: {{ $v | quote }}
      {{- end }}
      {{- range (index $parsedSecretEnvEntries "items") }}
      - name: {{ .name }}
        valueFrom:
          secretKeyRef:
            name: {{ .secretName }}
            key: {{ .key }}
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
    resources:
      {{- toYaml .Values.resources | nindent 6 }}
{{- end }}
