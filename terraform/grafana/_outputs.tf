output "prometheus_remote_endpoint" {
  value = module.grafana_cloud_dev.prometheus_remote_endpoint
}

output "prometheus_username" {
  value = module.grafana_cloud_dev.prometheus_username
}

output "prometheus_password" {
  value     = module.grafana_cloud_dev.prometheus_password
  sensitive = true
}
