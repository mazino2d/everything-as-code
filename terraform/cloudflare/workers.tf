# ===================================================================
# Workers deploy tokens
# ===================================================================
# One account-owned token per app repo, scoped to deploying Workers
# (scripts, Durable Object migrations, secrets). terraform/github hands
# each token to its repo's GitHub Actions via remote state.

locals {
  workers_deployer_permissions = [
    "Workers Scripts Write",
    "Account Settings Read",
  ]

  workers_deployers = ["a3spy"]
}

data "cloudflare_account_api_token_permission_groups_list" "workers_deployer" {
  for_each   = toset(local.workers_deployer_permissions)
  account_id = var.cloudflare_account_id
  name       = each.key
}

resource "cloudflare_account_token" "workers_deployer" {
  for_each   = toset(local.workers_deployers)
  account_id = var.cloudflare_account_id
  name       = "${each.key}-workers-deployer"

  policies = [{
    effect = "allow"
    permission_groups = [
      for p in data.cloudflare_account_api_token_permission_groups_list.workers_deployer : { id = one(p.result).id }
    ]
    resources = jsonencode({
      "com.cloudflare.api.account.${var.cloudflare_account_id}" = "*"
    })
  }]
}
