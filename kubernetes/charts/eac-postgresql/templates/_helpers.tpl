{{/*
Name of the Secret that holds an instance's POSTGRES_PASSWORD: the chart's own
(auth.password.secretName, default <name>-auth) unless source=existingSecret.
Usage: include "eac-postgresql.passwordSecretName" $instance
*/}}
{{- define "eac-postgresql.passwordSecretName" -}}
{{- if eq (dig "auth" "password" "source" "auto" .) "existingSecret" -}}
{{- required (printf "instances[%s].auth.password.existingSecret is required when source=existingSecret" .name) (dig "auth" "password" "existingSecret" "" .) -}}
{{- else -}}
{{- dig "auth" "password" "secretName" (printf "%s-auth" .name) . -}}
{{- end -}}
{{- end -}}
