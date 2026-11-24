terraform {
  required_version = "~> 1.14"

  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.11"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.4"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7"
    }
    restful = {
      source  = "magodo/restful"
      version = "~> 0.25.2"
    }
  }

  backend "gcs" {
    bucket = "mazino2d-as-se1-eac-tfstate"
    prefix = "state/github"
  }
}

provider "github" {
  token = var.github_token
  owner = var.github_owner
}

# GitHub REST API calls integrations/github has no resource for.
provider "restful" {
  base_url = "https://api.github.com"
  header = {
    Authorization        = "Bearer ${var.github_token}"
    Accept               = "application/vnd.github+json"
    X-GitHub-Api-Version = "2022-11-28"
  }
}
