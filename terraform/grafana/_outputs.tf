output "prometheus_remote_write_url" {
  value = module.grafana_cloud_dev.prometheus_remote_write_url
}

output "prometheus_username" {
  value = module.grafana_cloud_dev.prometheus_username
}

output "prometheus_password" {
  value     = module.grafana_cloud_dev.prometheus_password
  sensitive = true
}
