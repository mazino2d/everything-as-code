# ===================================================================
# Actions variables and secrets
# ===================================================================

# -------------------------------------------------------------------
# data-platform
# -------------------------------------------------------------------

resource "github_actions_variable" "data_platform" {
  for_each = local.data_platform_ci == null ? {} : {
    GCP_PROJECT_ID                 = local.data_platform_ci.project_id
    GCP_WORKLOAD_IDENTITY_PROVIDER = local.data_platform_ci.workload_identity_provider
    GCP_SERVICE_ACCOUNT            = local.data_platform_ci.service_account
  }

  repository    = module.data_platform.name
  variable_name = each.key
  value         = each.value
}

# Environments: dev runs CI on every branch and the pipeline on main against
# dataplatform-as-se1-dev; prd runs the pipeline against dataplatform-as-se1-prd
# from release tags, and on its daily schedule (whose ref is main; the workflow
# checks out the latest tag). The tag push is the release gate: no reviewer,
# or the daily run would wait for approval. Each holds the same variable names,
# so workflows read vars.X whichever environment their job targets. The
# repo-level GCP_* variables above stay until data-platform's workflows use
# the environments.
resource "github_repository_environment" "data_platform" {
  for_each = toset(["dev", "prd"])

  repository        = module.data_platform.name
  environment       = each.key
  can_admins_bypass = true

  dynamic "deployment_branch_policy" {
    for_each = each.key == "prd" ? [1] : []
    content {
      protected_branches     = false
      custom_branch_policies = true
    }
  }
}

resource "github_repository_environment_deployment_policy" "data_platform_prd_main" {
  repository     = module.data_platform.name
  environment    = github_repository_environment.data_platform["prd"].environment
  branch_pattern = "main"
}

resource "github_repository_environment_deployment_policy" "data_platform_prd_tags" {
  repository  = module.data_platform.name
  environment = github_repository_environment.data_platform["prd"].environment
  tag_pattern = "v*"
}

# Each variable is left out until the workspace it comes from has applied.
resource "github_actions_environment_variable" "data_platform" {
  for_each = {
    for item in flatten([
      for environment, variables in local.data_platform_environment_variables : [
        for name, value in variables : { environment = environment, name = name, value = value }
      ]
    ]) : "${item.environment}/${item.name}" => item if item.value != null
  }

  repository    = module.data_platform.name
  environment   = github_repository_environment.data_platform[each.value.environment].environment
  variable_name = each.value.name
  value         = each.value.value
}

# The Evidence dashboard (sim-split R-4) deploys to Cloudflare Pages with the
# Pages-only token minted by the cloudflare workspace; until it has, these are
# left out.
resource "github_actions_variable" "data_platform_dashboard" {
  for_each = nonsensitive(local.data_platform_dashboard != null) ? {
    CLOUDFLARE_ACCOUNT_ID = local.cloudflare_account_id
    DASHBOARD_PROJECT     = nonsensitive(local.data_platform_dashboard.project)
  } : {}

  repository    = module.data_platform.name
  variable_name = each.key
  value         = each.value
}

resource "github_actions_secret" "data_platform_cloudflare_api_token" {
  count       = nonsensitive(local.data_platform_dashboard != null) ? 1 : 0
  repository  = module.data_platform.name
  secret_name = "CLOUDFLARE_API_TOKEN"
  value       = local.data_platform_dashboard.token
}

# -------------------------------------------------------------------
# sim-split
# -------------------------------------------------------------------

# Environments: dev deploys from main, prd from release tags after the
# maintainer approves, and store syncs the Play store listing from main
# (play_metadata.yml, including pull_request_target runs, whose ref is main).
# Each holds the same variable names, so workflows read vars.X whichever
# environment their job targets.
data "github_user" "mazino2d" {
  username = "mazino2d"
}

resource "github_repository_environment" "sim_split" {
  for_each = toset(["dev", "prd", "store"])

  repository          = module.sim_split.name
  environment         = each.key
  can_admins_bypass   = each.key != "prd"
  prevent_self_review = false # the sole maintainer approves their own releases

  dynamic "reviewers" {
    for_each = each.key == "prd" ? [1] : []
    content {
      users = [tonumber(data.github_user.mazino2d.id)]
    }
  }

  deployment_branch_policy {
    protected_branches     = false
    custom_branch_policies = true
  }
}

resource "github_repository_environment_deployment_policy" "sim_split_main" {
  for_each = toset(["dev", "store"])

  repository     = module.sim_split.name
  environment    = github_repository_environment.sim_split[each.key].environment
  branch_pattern = "main"
}

resource "github_repository_environment_deployment_policy" "sim_split_prd_tags" {
  repository  = module.sim_split.name
  environment = github_repository_environment.sim_split["prd"].environment
  tag_pattern = "v*"
}

# Each variable is left out until the workspace it comes from has applied.
resource "github_actions_environment_variable" "sim_split" {
  for_each = {
    for item in flatten([
      for environment, variables in local.sim_split_environment_variables : [
        for name, value in variables : { environment = environment, name = name, value = value }
      ]
    ]) : "${item.environment}/${item.name}" => item if item.value != null
  }

  repository    = module.sim_split.name
  environment   = github_repository_environment.sim_split[each.value.environment].environment
  variable_name = each.value.name
  value         = each.value.value
}

# -------------------------------------------------------------------
# a3spy
# -------------------------------------------------------------------

resource "github_actions_variable" "a3spy_cloudflare_account_id" {
  count         = local.cloudflare_account_id != null ? 1 : 0
  repository    = module.a3spy.name
  variable_name = "CLOUDFLARE_ACCOUNT_ID"
  value         = local.cloudflare_account_id
}

resource "github_actions_secret" "a3spy_cloudflare_api_token" {
  count       = nonsensitive(local.a3spy_cloudflare_api_token != null) ? 1 : 0
  repository  = module.a3spy.name
  secret_name = "CLOUDFLARE_API_TOKEN"
  value       = local.a3spy_cloudflare_api_token
}

# Realtime SFU app minted by the cloudflare workspace: the CD workflow
# pushes the token to the Worker, which calls the Realtime API for voice.
resource "github_actions_variable" "a3spy_realtime_app_id" {
  count         = nonsensitive(local.a3spy_realtime_app != null) ? 1 : 0
  repository    = module.a3spy.name
  variable_name = "REALTIME_APP_ID"
  value         = nonsensitive(local.a3spy_realtime_app.id)
}

resource "github_actions_secret" "a3spy_realtime_app_token" {
  count       = nonsensitive(local.a3spy_realtime_app != null) ? 1 : 0
  repository  = module.a3spy.name
  secret_name = "REALTIME_APP_TOKEN"
  value       = local.a3spy_realtime_app.token
}

# Bot token comes from @BotFather, so it is set by hand as a sensitive
# variable on the github workspace; the CD workflow pushes it to the Worker.
resource "github_actions_secret" "a3spy_telegram_bot_token" {
  count       = var.a3spy_telegram_bot_token != null ? 1 : 0
  repository  = module.a3spy.name
  secret_name = "TELEGRAM_BOT_TOKEN"
  value       = var.a3spy_telegram_bot_token
}

# Only this Telegram user may send announcements to everyone who used the bot
# (/announce); set by hand on the github workspace, pushed to the Worker by CD.
resource "github_actions_secret" "a3spy_owner_telegram_id" {
  count       = var.a3spy_owner_telegram_id != null ? 1 : 0
  repository  = module.a3spy.name
  secret_name = "OWNER_TELEGRAM_ID"
  value       = var.a3spy_owner_telegram_id
}

# Telegram echoes this in X-Telegram-Bot-Api-Secret-Token on every webhook
# call, so the Worker can drop requests that did not come from Telegram.
resource "random_password" "a3spy_telegram_webhook_secret" {
  length  = 48
  special = false
}

resource "github_actions_secret" "a3spy_telegram_webhook_secret" {
  repository  = module.a3spy.name
  secret_name = "TELEGRAM_WEBHOOK_SECRET"
  value       = random_password.a3spy_telegram_webhook_secret.result
}
