resource "random_password" "apps_app_db_admin_password" {
  for_each = toset(local.environments)

  length           = 32
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "infisical_secret" "apps_app_db_admin_password" {
  for_each = toset(local.environments)

  name         = "admin_password"
  value_wo     = random_password.apps_app_db_admin_password[each.key].result
  value_wo_version = 1
  env_slug     = each.value
  workspace_id = module.everything_as_code.id
  folder_path  = infisical_secret_folder.apps_app_db[each.key].path
}
