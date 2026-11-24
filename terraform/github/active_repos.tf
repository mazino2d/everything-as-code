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
      contexts = ["terraform / gate", "k8s / gate", "blog / gate", "docker / gate"]
    }
  }

  # CodeQL default setup; replaces the advanced codeql job in .github/workflows/lint.yml.
  security = {
    code_scanning = true
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
  source      = "./_modules/github-repository"
  name        = "mazino2d.github.io"
  description = "My SPACE!"
  visibility  = "public"
  topics      = ["personal-website", "blog"]

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
    required_status_checks = {
      contexts = ["lint / gate", "dbt", "docs / gate"]
    }
  }

  deploy_app = local.eac_deploy_app
}

module "sim_split" {
  source      = "./_modules/github-repository"
  name        = "sim-split"
  description = "Flutter app for splitting group trip expenses with friends: shared groups that sync live and work offline, settle up through one person or in the fewest transfers. Android and web."
  visibility  = "public"
  topics      = ["flutter", "dart", "android", "offline-first"]

  pages = {
    build_type = "workflow"
  }

  branch_protection = {
    required_status_checks = {
      contexts = ["PR Validation"]
    }
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
  source      = "./_modules/github-repository"
  name        = "github-workflows"
  description = "Centralised reusable GitHub Actions workflows and composite actions"
  visibility  = "public"
  topics      = ["github-actions", "ci-cd", "reusable-workflows"]

  # release-please opens the release PR with the workflow token.
  actions_can_create_and_approve_pull_requests = true
}

module "a3spy" {
  source                = "./_modules/github-repository"
  name                  = "a3spy"
  description           = "Who is Spy game master in the browser: secret words, voting, and a voice call for friends far apart"
  visibility            = "public"
  topics                = ["game", "party-game", "pwa", "webrtc", "typescript", "cloudflare-workers"]
  rename_default_branch = true

  branch_protection = {
    required_status_checks = {
      contexts = ["ci / gate"]
    }
  }
}

# Default community health files (SECURITY.md, ...) for every repo without its own.
module "dot_github" {
  source      = "./_modules/github-repository"
  name        = ".github"
  description = "Default community health files for mazino2d repositories"
  visibility  = "public"
  topics      = ["community-health", "security-policy"]
}

# ===================================================================
# Active - Private
# ===================================================================

# GitHub Free does not allow branch protection on private repos.
module "curriculum_vitae" {
  source            = "./_modules/github-repository"
  name              = "curriculum-vitae"
  description       = "LaTeX source of my CV, built to PDF by CI"
  visibility        = "private"
  topics            = ["cv", "latex"]
  branch_protection = null
}
