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

# R-4 telemetry endpoint, built into sim-split's web and Android releases.
# Setting it starts sending error reports and usage events, so it ships with
# the release that updates the privacy policy (sim-split R-4 P5).
resource "github_actions_variable" "sim_split_telemetry_url" {
  count         = local.sim_split_telemetry_url != null ? 1 : 0
  repository    = module.sim_split.name
  variable_name = "TELEMETRY_URL"
  value         = local.sim_split_telemetry_url
}

resource "github_actions_variable" "sim_split_recaptcha_site_key" {
  count         = local.sim_split_recaptcha_site_key != null ? 1 : 0
  repository    = module.sim_split.name
  variable_name = "RECAPTCHA_ENTERPRISE_SITE_KEY"
  value         = local.sim_split_recaptcha_site_key
}

# Dev environment (gcp-simsplit-as-se1-dev): sim-split's workflows deploy
# Firestore rules, indexes and Hosting to it and build dev web bundles with its
# site key. Each variable is left out until that workspace has applied.
resource "github_actions_variable" "sim_split_dev" {
  for_each = { for name, value in local.sim_split_dev_variables : name => value if value != null }

  repository    = module.sim_split.name
  variable_name = each.key
  value         = each.value
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
