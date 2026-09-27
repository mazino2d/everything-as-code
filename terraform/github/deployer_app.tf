# ===================================================================
# eac-deployer GitHub App
# ===================================================================
# The App itself is created manually (GitHub has no API to create Apps)
# and installed on everything-as-code only. Terraform distributes its
# credentials to the repos below, which may then mint short-lived tokens
# to open image-bump PRs against everything-as-code.

locals {
  eac_deployer_repos = [
    "jaffle-shop",
  ]
}

resource "github_actions_variable" "eac_deployer_app_id" {
  for_each      = toset(local.eac_deployer_repos)
  repository    = each.key
  variable_name = "EAC_DEPLOYER_APP_ID"
  value         = var.eac_deployer_app_id
}

resource "github_actions_secret" "eac_deployer_private_key" {
  for_each        = toset(local.eac_deployer_repos)
  repository      = each.key
  secret_name     = "EAC_DEPLOYER_PRIVATE_KEY"
  plaintext_value = var.eac_deployer_app_private_key
}
