output "prometheus_remote_write_url" {
  value = local.stack.prometheus_remote_endpoint
}

output "prometheus_username" {
  value = tostring(local.stack.prometheus_user_id)
}

output "prometheus_password" {
  value     = grafana_cloud_access_policy_token.alloy.token
  sensitive = true
}
