locals {
  top_folders = {
    for item in flatten([
      for env in var.environments : [
        for top_name, _ in var.tree : {
          key      = "${env}:${replace(top_name, "/[^a-zA-Z0-9]+/", "_")}"
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
            key      = "${env}:${replace(top_name, "/[^a-zA-Z0-9]+/", "_")}_${replace(leaf_name, "/[^a-zA-Z0-9]+/", "_")}"
            env_slug = env
            name     = leaf_name
            top_ref  = "${env}:${replace(top_name, "/[^a-zA-Z0-9]+/", "_")}"
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
              key         = "${env}:${replace(top_name, "/[^a-zA-Z0-9]+/", "_")}_${replace(leaf_name, "/[^a-zA-Z0-9]+/", "_")}_${try(replace(lower(secret.key), "/[^a-z0-9]+/", "_"), "")}"
              env_slug    = env
              name        = try(secret.key, null)
              folder_ref  = "${env}:${replace(top_name, "/[^a-zA-Z0-9]+/", "_")}_${replace(leaf_name, "/[^a-zA-Z0-9]+/", "_")}"
              secret_envs = try(tolist(secret.environments), var.environments)
              value       = try(secret.value, null)
              generate    = try(secret.generate, null)
              generate_mode = lower(trimspace(tostring(try(secret.generate.mode, ""))))
              remote_state = try({
                workspace = secret.remote_state.workspace
                output    = secret.remote_state.output
                format    = try(secret.remote_state.format, null)
              }, null)
            }
          ]
        ]
      ]
    ]) : item.key => item
    if item.name != null && contains(item.secret_envs, item.env_slug)
  }

  secret_instances_with_generated_values = {
    for key, secret in local.secret_instances : key => secret
    if secret.generate != null && !contains(["openssl_rand_hex_32", "hex32"], secret.generate_mode)
  }

  secret_instances_with_generated_hex_values = {
    for key, secret in local.secret_instances : key => secret
    if secret.generate != null && contains(["openssl_rand_hex_32", "hex32"], secret.generate_mode)
  }

  secret_instances_with_remote_state_values = {
    for key, secret in local.secret_instances : key => secret
    if secret.remote_state != null
  }

  remote_state_workspaces = toset([
    for secret in values(local.secret_instances_with_remote_state_values) : secret.remote_state.workspace
  ])
}

data "terraform_remote_state" "workspaces" {
  for_each = local.remote_state_workspaces

  backend = "remote"
  config = {
    organization = var.remote_state_organization
    workspaces = {
      name = each.key
    }
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

resource "random_id" "generated_hex" {
  for_each = local.secret_instances_with_generated_hex_values

  byte_length = try(tonumber(each.value.generate.byte_length), 32)
}

resource "infisical_secret" "secrets" {
  for_each = local.secret_instances

  name = each.value.name
  value_wo = each.value.generate != null ? (
    contains(["openssl_rand_hex_32", "hex32"], each.value.generate_mode)
      ? random_id.generated_hex[each.key].hex
      : random_password.generated[each.key].result
  ) : (
    each.value.remote_state != null ? (
      each.value.remote_state.format != null ? format(
        each.value.remote_state.format,
        data.terraform_remote_state.workspaces[each.value.remote_state.workspace].outputs[each.value.remote_state.output]
      ) : data.terraform_remote_state.workspaces[each.value.remote_state.workspace].outputs[each.value.remote_state.output]
    ) : each.value.value
  )
  value_wo_version = 1
  env_slug         = each.value.env_slug
  workspace_id     = var.project_id
  folder_path      = infisical_secret_folder.folders_sub[each.value.folder_ref].path

  lifecycle {
    precondition {
      condition = (
        (each.value.generate != null ? 1 : 0) +
        (each.value.value != null ? 1 : 0) +
        (each.value.remote_state != null ? 1 : 0)
      ) == 1
      error_message = "Secret ${each.value.name} for env ${each.value.env_slug} needs exactly one of generate, value, or remote_state in secret_tree.yaml."
    }

    precondition {
      condition     = each.value.remote_state == null || can(data.terraform_remote_state.workspaces[each.value.remote_state.workspace].outputs[each.value.remote_state.output])
      error_message = "Secret ${each.value.name} for env ${each.value.env_slug} references missing remote_state output in secret_tree.yaml."
    }

    precondition {
      condition     = each.value.remote_state == null || each.value.remote_state.format == null || length(regexall("%s", each.value.remote_state.format)) == 1
      error_message = "Secret ${each.value.name} for env ${each.value.env_slug} requires remote_state.format to include exactly one %s placeholder."
    }

    precondition {
      condition     = each.value.generate == null || each.value.generate_mode == "" || contains(["openssl_rand_hex_32", "hex32"], each.value.generate_mode)
      error_message = "Secret ${each.value.name} for env ${each.value.env_slug} has unsupported generate.mode. Supported: openssl_rand_hex_32, hex32."
    }
  }
}
