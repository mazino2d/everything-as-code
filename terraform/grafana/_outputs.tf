output "dev_prometheus_remote_endpoint" {
  value = module.grafana_cloud_dev.prometheus_remote_endpoint
}

output "dev_prometheus_username" {
  value = module.grafana_cloud_dev.prometheus_username
}

output "dev_prometheus_password" {
  value     = module.grafana_cloud_dev.prometheus_password
  sensitive = true
}

output "dev_loki_endpoint" {
  value = module.grafana_cloud_dev.loki_endpoint
}

output "dev_loki_username" {
  value = module.grafana_cloud_dev.loki_username
}

output "dev_loki_password" {
  value     = module.grafana_cloud_dev.loki_password
  sensitive = true
}

output "dev_tempo_endpoint_without_scheme" {
  value = trimprefix(trimprefix(trimsuffix(module.grafana_cloud_dev.tempo_endpoint, "/"), "https://"), "http://")
}

output "dev_tempo_username" {
  value = module.grafana_cloud_dev.tempo_username
}

output "dev_tempo_password" {
  value     = module.grafana_cloud_dev.tempo_password
  sensitive = true
}
