terraform {
  required_version = "~> 1.14"

  required_providers {
    infisical = {
      source  = "infisical/infisical"
      version = "~> 0.12"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7"
    }
  }

  backend "gcs" {
    bucket = "mazino2d-as-se1-dev-tfstate"
    prefix = "state/infisical"
  }
}

provider "infisical" {
  host          = "https://app.infisical.com"
  client_id     = var.infisical_client_id
  client_secret = var.infisical_client_secret
}
