module "grafana_cloud_dev" {
  source = "./_modules/grafana-cloud-stack"

  create_stack      = false
  stack_slug        = "mazino2d"
  stack_name        = "mazino2d"
  stack_region_slug = "ap-southeast-0"
}

resource "infisical_secret" "dev_remote_write_url" {
  name         = "REMOTE_WRITE_URL"
  value        = module.grafana_cloud_dev.prometheus_remote_write_url
  env_slug     = "dev"
  workspace_id = var.infisical_project_id
  folder_path  = "/grafana-alloy"
}

resource "infisical_secret" "dev_remote_write_username" {
  name         = "REMOTE_WRITE_USERNAME"
  value        = module.grafana_cloud_dev.prometheus_username
  env_slug     = "dev"
  workspace_id = var.infisical_project_id
  folder_path  = "/grafana-alloy"
}

resource "infisical_secret" "dev_remote_write_password" {
  name         = "REMOTE_WRITE_PASSWORD"
  value        = module.grafana_cloud_dev.prometheus_password
  env_slug     = "dev"
  workspace_id = var.infisical_project_id
  folder_path  = "/grafana-alloy"
}
