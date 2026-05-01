locals {
  top_folders = {
    for item in flatten([
      for env in var.environments : [
        for top_name, _ in var.tree : {
          key      = "${env}:${regexreplace(top_name, "[^a-zA-Z0-9]+", "_")}"
          env_slug = env
          name     = top_name
        }
      ]
    ]) : item.key => item
  }

  sub_folders = {
    for item in flatten([
      for env in var.environments : [
        for top_name, children in var.tree : [
          for leaf_name, _ in children : {
            key      = "${env}:${regexreplace(top_name, "[^a-zA-Z0-9]+", "_")}_${regexreplace(leaf_name, "[^a-zA-Z0-9]+", "_")}"
            env_slug = env
            name     = leaf_name
            top_ref  = "${env}:${regexreplace(top_name, "[^a-zA-Z0-9]+", "_")}"
          }
        ]
      ]
    ]) : item.key => item
  }

  secret_instances = {
    for item in flatten([
      for env in var.environments : [
        for top_name, children in var.tree : [
          for leaf_name, leaf in children : [
            for secret in try(leaf.secrets, []) : {
              key        = "${env}:${regexreplace(top_name, "[^a-zA-Z0-9]+", "_")}_${regexreplace(leaf_name, "[^a-zA-Z0-9]+", "_")}_${try(regexreplace(lower(secret.key), "[^a-z0-9]+", "_"), "")}"
              env_slug   = env
              name       = try(secret.key, null)
              folder_ref = "${env}:${regexreplace(top_name, "[^a-zA-Z0-9]+", "_")}_${regexreplace(leaf_name, "[^a-zA-Z0-9]+", "_")}"
              value      = try(secret.value, null)
              generate   = try(secret.generate, null)
            }
          ]
        ]
      ]
    ]) : item.key => item
    if item.name != null
  }

  secret_instances_with_generated_values = {
    for key, secret in local.secret_instances : key => secret
    if secret.generate != null
  }
}

resource "infisical_secret_folder" "folders_top" {
  for_each = local.top_folders

  name             = each.value.name
  environment_slug = each.value.env_slug
  project_id       = var.project_id
  folder_path      = "/"
}

resource "infisical_secret_folder" "folders_sub" {
  for_each = local.sub_folders

  name             = each.value.name
  environment_slug = each.value.env_slug
  project_id       = var.project_id
  folder_path      = infisical_secret_folder.folders_top[each.value.top_ref].path
}

resource "random_password" "generated" {
  for_each = local.secret_instances_with_generated_values

  length           = try(tonumber(each.value.generate.length), 32)
  special          = try(each.value.generate.special, true)
  override_special = try(each.value.generate.override_special, "!#$%&*()-_=+[]{}<>:?")
}

resource "infisical_secret" "secrets" {
  for_each = local.secret_instances

  name             = each.value.name
  value_wo         = each.value.generate != null ? random_password.generated[each.key].result : each.value.value
  value_wo_version = 1
  env_slug         = each.value.env_slug
  workspace_id     = var.project_id
  folder_path      = infisical_secret_folder.folders_sub[each.value.folder_ref].path

  lifecycle {
    precondition {
      condition     = each.value.generate != null || each.value.value != null
      error_message = "Secret ${each.value.name} for env ${each.value.env_slug} needs either generate or value in secret_tree.yaml."
    }
  }
}
