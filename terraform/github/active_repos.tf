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
      contexts = ["terraform / gate", "k8s / gate", "blog / gate", "docker / gate"]
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
    build_type = "workflow"
  }
}

module "caketool" {
  source      = "./_modules/github-repository"
  name        = "caketool"
  description = "Machine learning library"
  visibility  = "public"
  topics      = ["machine-learning", "python"]

  pages = {
    build_type = "workflow"
  }

  branch_protection = {
    required_status_checks = {
      contexts = ["ci / gate", "docs / gate"]
    }
  }
}

module "data_platform" {
  source      = "./_modules/github-repository"
  name        = "data-platform"
  description = "Data platform for mazino2d projects: dlt, BigQuery, dbt and Evidence"
  visibility  = "public"
  topics      = ["dbt", "bigquery", "data-engineering", "analytics"]

  pages = {
    build_type = "workflow"
  }

  branch_protection = {
    require_conversation_resolution = true
    required_status_checks = {
      contexts = ["lint / gate", "dbt", "docs / gate"]
    }
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
    build_type = "workflow"
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

  # release-please opens the release PR with the workflow token.
  actions_can_create_and_approve_pull_requests = true
}

module "a3spy" {
  source                = "./_modules/github-repository"
  name                  = "a3spy"
  description           = "Who is Spy game master in the browser: secret words, voting, and a voice call for friends far apart"
  visibility            = "public"
  topics                = ["game", "party-game", "pwa", "webrtc", "typescript", "cloudflare-workers"]
  has_wiki              = false
  has_projects          = false
  rename_default_branch = true

  branch_protection = {
    required_status_checks = {
      strict   = true
      contexts = ["ci / gate"]
    }
  }

  security = {
    dependabot_alerts           = true
    dependabot_security_updates = true
    secret_scanning             = true
  }
}
