# ===================================================================
# eac-deployer GitHub App
# ===================================================================
# The App itself is created manually (GitHub has no API to create Apps)
# and installed on everything-as-code only. Repos with deploy_app set
# receive its credentials and may mint short-lived tokens to open
# image-bump PRs against everything-as-code.

locals {
  eac_deploy_app = {
    app_id      = var.eac_deployer_app_id
    private_key = var.eac_deployer_app_private_key
  }
}
