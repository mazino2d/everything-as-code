locals {
  workload_gsa_sync = {
    sources = [
      {
        workspace   = "gcp-mazino2d-as-se1-dev"
        environment = "dev"
      },
    ]
  }

  workload_gsa_sources = {
    for source in local.workload_gsa_sync.sources : source.workspace => {
      workspace      = source.workspace
      environment    = source.environment
      workspace_slug = replace(lower(source.workspace), "/[^a-z0-9-]+/", "-")
    }
  }
}

data "terraform_remote_state" "gcp_workload_gsa" {
  for_each = local.workload_gsa_sources

  backend = "remote"

  config = {
    organization = var.remote_state_organization
    workspaces = {
      name = each.value.workspace
    }
  }
}

locals {
  all_sync_environments = toset([
    for source in values(local.workload_gsa_sources) : source.environment
  ])

  env_workspace_pairs = {
    for workspace_name, source in local.workload_gsa_sources : "${source.environment}:${workspace_name}" => {
      env_slug       = source.environment
      workspace_name = workspace_name
      workspace_slug = source.workspace_slug
    }
  }

  workload_gsa = {
    for workspace_name, state in data.terraform_remote_state.gcp_workload_gsa :
    workspace_name => try(state.outputs.workload_gsa, {})
  }

  workload_gsa_with_keys = {
    for item in flatten([
      for workspace_name, workloads in local.workload_gsa : [
        for workload_name, workload in workloads : {
          key            = "${local.workload_gsa_sources[workspace_name].environment}:${workspace_name}:${workload_name}"
          env_slug       = local.workload_gsa_sources[workspace_name].environment
          workspace_name = workspace_name
          workspace_slug = local.workload_gsa_sources[workspace_name].workspace_slug
          workload_name  = workload_name
          workload       = workload
        }
      ]
    ]) : item.key => item
    if try(item.workload.key_json, null) != null
  }
}

resource "infisical_secret_folder" "workload_gsa_root" {
  for_each = local.all_sync_environments

  name             = "workload-gsa-keys"
  environment_slug = each.value
  project_id       = module.everything_as_code.id
  folder_path      = "/"
}

resource "infisical_secret_folder" "workload_gsa_workspace" {
  for_each = local.env_workspace_pairs

  name             = each.value.workspace_slug
  environment_slug = each.value.env_slug
  project_id       = module.everything_as_code.id
  folder_path      = infisical_secret_folder.workload_gsa_root[each.value.env_slug].path
}

resource "infisical_secret_folder" "workload_gsa_sub" {
  for_each = local.workload_gsa_with_keys

  name             = each.value.workload_name
  environment_slug = each.value.env_slug
  project_id       = module.everything_as_code.id
  folder_path      = infisical_secret_folder.workload_gsa_workspace["${each.value.env_slug}:${each.value.workspace_name}"].path
}

resource "infisical_secret" "workload_gsa_key" {
  for_each = local.workload_gsa_with_keys

  name             = "gcp_service_account_json"
  value_wo         = each.value.workload.key_json
  value_wo_version = 1
  env_slug         = each.value.env_slug
  workspace_id     = module.everything_as_code.id
  folder_path      = infisical_secret_folder.workload_gsa_sub[each.key].path
}
