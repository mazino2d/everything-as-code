terraform {
  required_version = "~> 1.14"

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.27"
    }
  }

  cloud {
    organization = "mazino2d-everything-as-code"

    workspaces {
      name = "cloudflare"
    }
  }
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}
