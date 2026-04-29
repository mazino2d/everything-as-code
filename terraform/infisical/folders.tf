locals {
  environments = ["dev", "staging", "prod"]
}

# monitoring/
resource "infisical_secret_folder" "monitoring" {
  for_each         = toset(local.environments)
  name             = "monitoring"
  environment_slug = each.value
  project_id       = module.everything_as_code.id
  folder_path      = "/"
}

# apps/
resource "infisical_secret_folder" "apps" {
  for_each         = toset(local.environments)
  name             = "apps"
  environment_slug = each.value
  project_id       = module.everything_as_code.id
  folder_path      = "/"
}

# apps/app-db
resource "infisical_secret_folder" "apps_app_db" {
  for_each         = toset(local.environments)
  name             = "app-db"
  environment_slug = each.value
  project_id       = module.everything_as_code.id
  folder_path      = "/apps"

  depends_on = [infisical_secret_folder.apps]
}

# monitoring/grafana-alloy
resource "infisical_secret_folder" "monitoring_grafana_alloy" {
  for_each         = toset(local.environments)
  name             = "grafana-alloy"
  environment_slug = each.value
  project_id       = module.everything_as_code.id
  folder_path      = "/monitoring"

  depends_on = [infisical_secret_folder.monitoring]
}
