# ===================================================================
# Realtime SFU apps
# ===================================================================
# One SFU app per app repo that needs voice. The app's secret is the
# bearer token its Worker uses to call the Realtime API at runtime;
# terraform/github hands it to the repo's GitHub Actions via remote state.

# The provider (5.27–5.28) does not store app_id when it creates an app, yet
# reads the app back by app_id, so every later plan fails. Each app's id (its
# uid, not a secret) is set here after creation and was written into the
# state once by hand. A new app: add it with null, apply, then fill in its uid
# and patch the state the same way.
locals {
  realtime_apps = {
    a3spy = "2578aff8745a85e8333679f34f814cb9"
  }
}

resource "cloudflare_calls_sfu_app" "app" {
  for_each   = local.realtime_apps
  account_id = var.cloudflare_account_id
  name       = each.key
  app_id     = each.value
}
