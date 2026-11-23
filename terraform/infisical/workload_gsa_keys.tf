# Stacks whose workload_gsa output holds service account keys, synced to
# Infisical under /workload-gsa-keys/<folder>/<workload>. The key is the folder
# (Velero reads /workload-gsa-keys/gcp-mazino2d-as-se1-dev/velero-velero);
# stack is the state path under terraform/.
locals {
  workload_gsa_sources = {
    "gcp-mazino2d-as-se1-dev" = {
      stack       = "gcp/mazino2d-as-se1-dev"
      environment = "dev"
    }
  }
}

data "terraform_remote_state" "gcp_workload_gsa" {
  for_each = local.workload_gsa_sources

  backend = "gcs"

  config = {
    bucket = local.remote_state_bucket
    prefix = "state/${each.value.stack}"
  }
}

locals {
  all_sync_environments = toset([
    for source in values(local.workload_gsa_sources) : source.environment
  ])

  env_folder_pairs = {
    for folder, source in local.workload_gsa_sources : "${source.environment}:${folder}" => {
      env_slug = source.environment
      folder   = folder
    }
  }

  workload_gsa_with_keys = {
    for item in flatten([
      for folder, state in data.terraform_remote_state.gcp_workload_gsa : [
        for workload_name, workload in try(state.outputs.workload_gsa, {}) : {
          key           = "${local.workload_gsa_sources[folder].environment}:${folder}:${workload_name}"
          env_slug      = local.workload_gsa_sources[folder].environment
          folder        = folder
          workload_name = workload_name
          workload      = workload
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
  force_delete     = true
}

moved {
  from = infisical_secret_folder.workload_gsa_workspace
  to   = infisical_secret_folder.workload_gsa_folder
}

resource "infisical_secret_folder" "workload_gsa_folder" {
  for_each = local.env_folder_pairs

  name             = each.value.folder
  environment_slug = each.value.env_slug
  project_id       = module.everything_as_code.id
  # Static paths below: referencing a parent's computed path forces replacement whenever the parent is updated in place.
  folder_path  = "/workload-gsa-keys"
  force_delete = true

  depends_on = [infisical_secret_folder.workload_gsa_root]
}

resource "infisical_secret_folder" "workload_gsa_sub" {
  for_each = local.workload_gsa_with_keys

  name             = each.value.workload_name
  environment_slug = each.value.env_slug
  project_id       = module.everything_as_code.id
  folder_path      = "/workload-gsa-keys/${each.value.folder}"
  force_delete     = true

  depends_on = [infisical_secret_folder.workload_gsa_folder]
}

resource "infisical_secret" "workload_gsa_key" {
  for_each = local.workload_gsa_with_keys

  name             = "gcp_service_account_json"
  value_wo         = each.value.workload.key_json
  value_wo_version = 1
  env_slug         = each.value.env_slug
  workspace_id     = module.everything_as_code.id
  folder_path      = "/workload-gsa-keys/${each.value.folder}/${each.value.workload_name}"

  depends_on = [infisical_secret_folder.workload_gsa_sub]
}
