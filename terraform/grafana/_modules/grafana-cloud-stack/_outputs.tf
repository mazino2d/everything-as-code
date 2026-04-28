output "prometheus_remote_endpoint" {
  value = local.stack.prometheus_remote_endpoint
}

output "prometheus_username" {
  value = tostring(local.stack.prometheus_user_id)
}

output "prometheus_password" {
  value     = grafana_cloud_access_policy_token.alloy.token
  sensitive = true
}

output "loki_endpoint" {
  value = local.stack.logs_url
}

output "loki_username" {
  value = tostring(local.stack.logs_user_id)
}

output "loki_password" {
  value     = grafana_cloud_access_policy_token.alloy.token
  sensitive = true
}

output "tempo_endpoint" {
  value = local.stack.traces_url
}

output "tempo_username" {
  value = tostring(local.stack.traces_user_id)
}

output "tempo_password" {
  value     = grafana_cloud_access_policy_token.alloy.token
  sensitive = true
}
