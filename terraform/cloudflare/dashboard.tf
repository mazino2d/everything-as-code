# ===================================================================
# data-platform dashboard (sim-split R-4)
# ===================================================================
# Evidence builds a static site whose pages embed query results, so it is
# served from Cloudflare Pages behind Cloudflare Access: only the maintainer
# can open it. data-platform's GitHub Actions deploys the build with
# `wrangler pages deploy`, using the Pages deploy token below (handed to the
# repo by terraform/github). Pages direct uploads and Access (up to 50 users)
# are free.

locals {
  dashboard_project = "data-platform-dashboard"
  dashboard_viewers = ["mazino2d@gmail.com"]
}

resource "cloudflare_pages_project" "dashboard" {
  account_id        = var.cloudflare_account_id
  name              = local.dashboard_project
  production_branch = "main"
}

resource "cloudflare_zero_trust_access_policy" "dashboard_viewers" {
  account_id = var.cloudflare_account_id
  name       = "data-platform dashboard viewers"
  decision   = "allow"
  include    = [for email in local.dashboard_viewers : { email = { email = email } }]
}

# Covers the production site and every preview deployment
# (<hash>.data-platform-dashboard.pages.dev). Sign-in is a one-time PIN
# emailed to an allowed address. Access accepts a pages.dev hostname only once
# the Pages project exists in the account, so the domain comes from the
# project (which also orders the two).
resource "cloudflare_zero_trust_access_application" "dashboard" {
  account_id       = var.cloudflare_account_id
  name             = "data-platform dashboard"
  type             = "self_hosted"
  session_duration = "24h"

  destinations = [
    { type = "public", uri = cloudflare_pages_project.dashboard.subdomain },
    { type = "public", uri = "*.${cloudflare_pages_project.dashboard.subdomain}" },
  ]

  policies = [{
    id         = cloudflare_zero_trust_access_policy.dashboard_viewers.id
    precedence = 1
  }]
}

# Deploy token for data-platform: Pages only.
data "cloudflare_account_api_token_permission_groups_list" "pages_deployer" {
  account_id = var.cloudflare_account_id
  name       = "Pages Write"
}

resource "cloudflare_account_token" "pages_deployer" {
  account_id = var.cloudflare_account_id
  name       = "data-platform-pages-deployer"

  policies = [{
    effect            = "allow"
    permission_groups = [{ id = one(data.cloudflare_account_api_token_permission_groups_list.pages_deployer.result).id }]
    resources = jsonencode({
      "com.cloudflare.api.account.${var.cloudflare_account_id}" = "*"
    })
  }]
}

# Dev dashboard: data-platform deploys the build from main, which reads
# dataplatform-as-se1-dev (dev telemetry, dev Firestore and fake data). Same
# viewers and deploy token as prd.
resource "cloudflare_pages_project" "dashboard_dev" {
  account_id        = var.cloudflare_account_id
  name              = "${local.dashboard_project}-dev"
  production_branch = "main"
}

resource "cloudflare_zero_trust_access_application" "dashboard_dev" {
  account_id       = var.cloudflare_account_id
  name             = "data-platform dashboard (dev)"
  type             = "self_hosted"
  session_duration = "24h"

  destinations = [
    { type = "public", uri = cloudflare_pages_project.dashboard_dev.subdomain },
    { type = "public", uri = "*.${cloudflare_pages_project.dashboard_dev.subdomain}" },
  ]

  policies = [{
    id         = cloudflare_zero_trust_access_policy.dashboard_viewers.id
    precedence = 1
  }]
}
