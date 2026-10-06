# ===================================================================
# Active - Public
# ===================================================================

module "everything_as_code" {
  source      = "./_modules/github-repository"
  name        = "everything-as-code"
  description = "Infrastructure, platform, and tooling managed as code"
  visibility  = "public"
  topics      = ["terraform", "iac", "gitops", "github"]

  pages = {
    build_type = "workflow"
  }

  branch_protection = {
    required_status_checks = {
      strict   = true
      contexts = ["check-terraform", "check-k8s", "check-blog", "check-docker"]
    }
  }
}

module "mazino2d" {
  source      = "./_modules/github-repository"
  name        = "mazino2d"
  description = "GitHub profile README :D"
  visibility  = "public"
  topics      = ["profile"]
}

module "mazino2d_github_io" {
  source       = "./_modules/github-repository"
  name         = "mazino2d.github.io"
  description  = "My SPACE!"
  visibility   = "public"
  topics       = ["personal-website", "blog"]
  has_wiki     = false
  has_projects = false

  pages = {
    branch = "main"
    path   = "/"
  }
}

module "caketool" {
  source      = "./_modules/github-repository"
  name        = "caketool"
  description = "Machine learning library"
  visibility  = "public"
  topics      = ["machine-learning", "python"]

  pages = {
    branch = "gh-pages"
    path   = "/docs"
  }
}

module "jaffle_shop" {
  source      = "./_modules/github-repository"
  name        = "jaffle-shop"
  description = "dbt learning playground based on the Jaffle Shop demo"
  visibility  = "public"
  topics      = ["dbt", "data-engineering", "analytics"]

  pages = {
    build_type = "workflow"
  }

  deploy_app = local.eac_deploy_app
}

module "sim_split" {
  source      = "./_modules/github-repository"
  name        = "sim-split"
  description = "Offline-first Flutter app for tracking and splitting group expenses"
  visibility  = "public"
  topics      = ["flutter", "dart", "android", "offline-first"]

  pages = {
    branch = "main"
    path   = "/docs"
  }

  branch_protection = {
    required_status_checks = {
      strict   = false
      contexts = ["PR Validation"]
    }
  }

  security = {
    dependabot_alerts           = true
    dependabot_security_updates = true
    secret_scanning             = true
  }
}

# reCAPTCHA site key for App Check on web, built into sim-split's web release
# (firebase_deploy.yml). Created by the gcp-simsplit-as-se1-prd workspace; until
# that workspace has applied, the variable is left out.
data "terraform_remote_state" "simsplit" {
  backend = "remote"

  config = {
    organization = "mazino2d-everything-as-code"
    workspaces = {
      name = "gcp-simsplit-as-se1-prd"
    }
  }
}

locals {
  sim_split_recaptcha_site_key = try(data.terraform_remote_state.simsplit.outputs.app_check.recaptcha_site_key, null)
}

resource "github_actions_variable" "sim_split_recaptcha_site_key" {
  count         = local.sim_split_recaptcha_site_key != null ? 1 : 0
  repository    = module.sim_split.name
  variable_name = "RECAPTCHA_ENTERPRISE_SITE_KEY"
  value         = local.sim_split_recaptcha_site_key
}

module "staged_recipes" {
  source      = "./_modules/github-repository"
  name        = "staged-recipes"
  description = "Conda recipes staged before publishing to conda-forge"
  visibility  = "public"
  topics      = ["conda", "conda-forge", "data-science"]
}

module "github_workflows" {
  source       = "./_modules/github-repository"
  name         = "github-workflows"
  description  = "Centralised reusable GitHub Actions workflows and composite actions"
  visibility   = "public"
  topics       = ["github-actions", "ci-cd", "reusable-workflows"]
  has_wiki     = false
  has_projects = false
}
