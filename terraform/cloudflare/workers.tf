# ===================================================================
# Workers deploy tokens
# ===================================================================
# One account-owned token per app repo, scoped to deploying Workers
# (scripts, Durable Object migrations, secrets) and Pages (a3spy's short
# link below). terraform/github hands each token to its repo's GitHub
# Actions via remote state.

locals {
  workers_deployer_permissions = [
    "Workers Scripts Write",
    "Account Settings Read",
    "Pages Write",
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

# ===================================================================
# a3spy short link: a3spy.pages.dev
# ===================================================================
# Friends could not remember a3spy.mazino2d.workers.dev. A Pages project's
# URL has no account name in it, so this project serves the whole game at
# a3spy.pages.dev: a3spy's CD deploys a one-line _worker.js that hands every
# request (WebSocket upgrades too) to the a3spy Worker through a service
# binding. The binding lives in a3spy's pages/wrangler.jsonc, which becomes
# the project's configuration on each deploy, so deployment_configs is left
# to it. The Worker builds links from the request's origin, so rooms opened
# there share pages.dev links; the workers.dev URL keeps working for phones
# that already installed it. Direct uploads, Functions and service bindings
# are free.
resource "cloudflare_pages_project" "a3spy" {
  account_id        = var.cloudflare_account_id
  name              = "a3spy"
  production_branch = "main"
}
