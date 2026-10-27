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

# The same for the dev warehouse, used by data-platform's dev environment.
data "terraform_remote_state" "dataplatform_dev" {
  backend = "remote"

  config = {
    organization = "mazino2d-everything-as-code"
    workspaces = {
      name = "gcp-dataplatform-as-se1-dev"
    }
  }

  defaults = {
    data_platform_ci = null
  }
}

# reCAPTCHA site key for App Check on web, built into sim-split's web release
# (firebase_deploy.yml), and the deploy identity for the prd environment.
data "terraform_remote_state" "simsplit" {
  backend = "remote"

  config = {
    organization = "mazino2d-everything-as-code"
    workspaces = {
      name = "gcp-simsplit-as-se1-prd"
    }
  }

  defaults = {
    firebase          = null
    firebase_deployer = null
    app_check         = null
    telemetry         = null
  }
}

# sim-split's dev Firebase project: deploy identity, reCAPTCHA site key and
# telemetry endpoint for dev builds and deploys.
data "terraform_remote_state" "simsplit_dev" {
  backend = "remote"

  config = {
    organization = "mazino2d-everything-as-code"
    workspaces = {
      name = "gcp-simsplit-as-se1-dev"
    }
  }

  defaults = {
    firebase          = null
    firebase_deployer = null
    app_check         = null
    telemetry         = null
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
    dashboard               = null
    dashboard_dev           = null
    realtime_apps           = {}
  }
}

locals {
  data_platform_ci             = data.terraform_remote_state.dataplatform.outputs.data_platform_ci
  sim_split_recaptcha_site_key = try(data.terraform_remote_state.simsplit.outputs.app_check.recaptcha_site_key, null)
  sim_split_telemetry_url      = try(data.terraform_remote_state.simsplit.outputs.telemetry.url, null)
  cloudflare_account_id        = try(data.terraform_remote_state.cloudflare.outputs.account_id, null)
  data_platform_dashboard      = data.terraform_remote_state.cloudflare.outputs.dashboard
  a3spy_cloudflare_api_token   = lookup(data.terraform_remote_state.cloudflare.outputs.workers_deployer_tokens, "a3spy", null)
  a3spy_realtime_app           = lookup(data.terraform_remote_state.cloudflare.outputs.realtime_apps, "a3spy", null)
  sim_split_environment_variables = {
    dev = {
      FIREBASE_PROJECT               = try(data.terraform_remote_state.simsplit_dev.outputs.firebase.project_id, null)
      GCP_WORKLOAD_IDENTITY_PROVIDER = try(data.terraform_remote_state.simsplit_dev.outputs.firebase_deployer.workload_identity_provider, null)
      GCP_FIREBASE_DEPLOYER          = try(data.terraform_remote_state.simsplit_dev.outputs.firebase_deployer.service_account, null)
      RECAPTCHA_ENTERPRISE_SITE_KEY  = try(data.terraform_remote_state.simsplit_dev.outputs.app_check.recaptcha_site_key, null)
      TELEMETRY_URL                  = try(data.terraform_remote_state.simsplit_dev.outputs.telemetry.url, null)
      TELEMETRY_IMAGE_REPOSITORY     = try(data.terraform_remote_state.simsplit_dev.outputs.telemetry.image_repository, null)
      GCP_TELEMETRY_DEPLOYER         = try(data.terraform_remote_state.simsplit_dev.outputs.telemetry.deployer_service_account, null)
    }
    prd = {
      FIREBASE_PROJECT               = try(data.terraform_remote_state.simsplit.outputs.firebase.project_id, null)
      GCP_WORKLOAD_IDENTITY_PROVIDER = try(data.terraform_remote_state.simsplit.outputs.firebase_deployer.workload_identity_provider, null)
      GCP_FIREBASE_DEPLOYER          = try(data.terraform_remote_state.simsplit.outputs.firebase_deployer.service_account, null)
      RECAPTCHA_ENTERPRISE_SITE_KEY  = local.sim_split_recaptcha_site_key
      TELEMETRY_URL                  = local.sim_split_telemetry_url
      TELEMETRY_IMAGE_REPOSITORY     = try(data.terraform_remote_state.simsplit.outputs.telemetry.image_repository, null)
      GCP_TELEMETRY_DEPLOYER         = try(data.terraform_remote_state.simsplit.outputs.telemetry.deployer_service_account, null)
    }
  }
  data_platform_environment_variables = {
    dev = {
      GCP_PROJECT_ID                 = try(data.terraform_remote_state.dataplatform_dev.outputs.data_platform_ci.project_id, null)
      GCP_WORKLOAD_IDENTITY_PROVIDER = try(data.terraform_remote_state.dataplatform_dev.outputs.data_platform_ci.workload_identity_provider, null)
      GCP_SERVICE_ACCOUNT            = try(data.terraform_remote_state.dataplatform_dev.outputs.data_platform_ci.service_account, null)
      SIMSPLIT_FIREBASE_PROJECT      = try(data.terraform_remote_state.simsplit_dev.outputs.firebase.project_id, null)
      DASHBOARD_PROJECT              = try(data.terraform_remote_state.cloudflare.outputs.dashboard_dev.project, null)
    }
    prd = {
      GCP_PROJECT_ID                 = try(local.data_platform_ci.project_id, null)
      GCP_WORKLOAD_IDENTITY_PROVIDER = try(local.data_platform_ci.workload_identity_provider, null)
      GCP_SERVICE_ACCOUNT            = try(local.data_platform_ci.service_account, null)
      SIMSPLIT_FIREBASE_PROJECT      = try(data.terraform_remote_state.simsplit.outputs.firebase.project_id, null)
      DASHBOARD_PROJECT              = try(nonsensitive(local.data_platform_dashboard.project), null)
    }
  }
}
