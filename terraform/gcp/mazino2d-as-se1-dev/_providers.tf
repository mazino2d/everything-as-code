terraform {
  required_version = "~> 1.14"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }

  cloud {
    organization = "mazino2d-everything-as-code"

    workspaces {
      name = "gcp-mazino2d-as-se1-dev"
    }
  }
}

provider "google" {
  credentials = var.gcp_credentials
  project     = "mazino2d-as-se1-dev"
}
