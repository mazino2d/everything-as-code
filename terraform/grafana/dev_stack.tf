module "grafana_cloud_dev" {
  source = "./_modules/grafana-cloud-stack"

  create_stack      = false
  stack_slug        = "mazino2d"
  stack_name        = "mazino2d"
  stack_region_slug = "prod-ap-southeast-1"
}

resource "infisical_secret" "dev_remote_write_url" {
  name         = "PROMETHEUS_URL"
  value        = "${trimsuffix(module.grafana_cloud_dev.prometheus_remote_endpoint, "/")}/push"
  env_slug     = "dev"
  workspace_id = var.infisical_project_id
  folder_path  = "/monitoring/grafana-alloy"
}

resource "infisical_secret" "dev_remote_write_username" {
  name         = "PROMETHEUS_USERNAME"
  value        = module.grafana_cloud_dev.prometheus_username
  env_slug     = "dev"
  workspace_id = var.infisical_project_id
  folder_path  = "/monitoring/grafana-alloy"
}

resource "infisical_secret" "dev_remote_write_password" {
  name         = "PROMETHEUS_PASSWORD"
  value        = module.grafana_cloud_dev.prometheus_password
  env_slug     = "dev"
  workspace_id = var.infisical_project_id
  folder_path  = "/monitoring/grafana-alloy"
}

resource "infisical_secret" "dev_loki_url" {
  name         = "LOKI_URL"
  value        = module.grafana_cloud_dev.loki_endpoint
  env_slug     = "dev"
  workspace_id = var.infisical_project_id
  folder_path  = "/monitoring/grafana-alloy"
}

resource "infisical_secret" "dev_loki_username" {
  name         = "LOKI_USERNAME"
  value        = module.grafana_cloud_dev.loki_username
  env_slug     = "dev"
  workspace_id = var.infisical_project_id
  folder_path  = "/monitoring/grafana-alloy"
}

resource "infisical_secret" "dev_loki_password" {
  name         = "LOKI_PASSWORD"
  value        = module.grafana_cloud_dev.loki_password
  env_slug     = "dev"
  workspace_id = var.infisical_project_id
  folder_path  = "/monitoring/grafana-alloy"
}
