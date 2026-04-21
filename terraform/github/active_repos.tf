# ===================================================================
# Active - Public
# ===================================================================

module "everything_as_code" {
  source      = "./_modules/github-repository"
  name        = "everything-as-code"
  description = "Infrastructure, platform, and tooling managed as code"
  visibility  = "public"
  topics      = ["terraform", "iac", "gitops", "github"]

  branch_protection = {
    required_status_checks = {
      strict   = true
      contexts = ["plan"]
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
}

module "sim_split" {
  source      = "./_modules/github-repository"
  name        = "sim-split"
  description = "Bill splitting simulation app"
  visibility  = "public"
  topics      = ["flutter", "dart"]
}

module "staged_recipes" {
  source      = "./_modules/github-repository"
  name        = "staged-recipes"
  description = "Conda recipes staged before publishing to conda-forge"
  visibility  = "public"
  topics      = ["conda", "conda-forge", "data-science"]
}
