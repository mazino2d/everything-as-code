# ===================================================================
# Realtime SFU apps
# ===================================================================
# One SFU app per app repo that needs voice. The app's secret is the
# bearer token its Worker uses to call the Realtime API at runtime;
# terraform/github hands it to the repo's GitHub Actions via remote state.

locals {
  realtime_apps = ["a3spy"]
}

resource "cloudflare_calls_sfu_app" "app" {
  for_each   = toset(local.realtime_apps)
  account_id = var.cloudflare_account_id
  name       = each.key
}
