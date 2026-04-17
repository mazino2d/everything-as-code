terraform {
  required_version = "~> 1.14"

  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.11"
    }
  }

  cloud {
    organization = "mazino2d-everything-as-code"

    workspaces {
      name = "github"
    }
  }
}

provider "github" {
  token = var.github_token
  owner = var.github_owner
}
