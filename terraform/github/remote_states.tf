# ===================================================================
# Remote state of other workspaces
# ===================================================================
# Each repo's Actions variables and secrets (actions.tf) are read from here.
# Until a workspace has applied, its outputs fall back to the defaults and the
# variables and secrets built from them are left out.

# Keyless BigQuery access for data-platform's workflows (WIF provider and
# service account).
data "terraform_remote_state" "dataplatform" {
  backend = "remote"

  config = {
    organization = "mazino2d-everything-as-code"
    workspaces = {
      name = "gcp-dataplatform-as-se1-prd"
    }
  }

  defaults = {
    data_platform_ci = null
  }
}

# reCAPTCHA site key for App Check on web, built into sim-split's web release
# (firebase_deploy.yml).
data "terraform_remote_state" "simsplit" {
  backend = "remote"

  config = {
    organization = "mazino2d-everything-as-code"
    workspaces = {
      name = "gcp-simsplit-as-se1-prd"
    }
  }

  defaults = {
    app_check = null
  }
}

# Workers deploy token and Realtime SFU app for a3spy.
data "terraform_remote_state" "cloudflare" {
  backend = "remote"

  config = {
    organization = "mazino2d-everything-as-code"
    workspaces = {
      name = "cloudflare"
    }
  }

  defaults = {
    account_id              = null
    workers_deployer_tokens = {}
    realtime_apps           = {}
  }
}

locals {
  data_platform_ci             = data.terraform_remote_state.dataplatform.outputs.data_platform_ci
  sim_split_recaptcha_site_key = try(data.terraform_remote_state.simsplit.outputs.app_check.recaptcha_site_key, null)
  cloudflare_account_id        = try(data.terraform_remote_state.cloudflare.outputs.account_id, null)
  a3spy_cloudflare_api_token   = lookup(data.terraform_remote_state.cloudflare.outputs.workers_deployer_tokens, "a3spy", null)
  a3spy_realtime_app           = lookup(data.terraform_remote_state.cloudflare.outputs.realtime_apps, "a3spy", null)
}
