terraform {
  required_version = "~> 1.14"

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.26"
    }
  }

  cloud {
    organization = "mazino2d-everything-as-code"

    workspaces {
      name = "cloudflare"
    }
  }
}

# Reads the GKE Service CIDR and kube-dns IP so they are not hard-coded here.
data "terraform_remote_state" "gcp" {
  backend = "remote"

  config = {
    organization = "mazino2d-everything-as-code"
    workspaces = {
      name = "gcp-mazino2d-as-se1-dev"
    }
  }
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}
