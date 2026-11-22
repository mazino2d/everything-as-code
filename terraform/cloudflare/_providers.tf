terraform {
  required_version = "~> 1.14"

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.27"
    }
  }

  backend "gcs" {
    bucket = "mazino2d-as-se1-dev-tfstate"
    prefix = "state/cloudflare"
  }
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}
