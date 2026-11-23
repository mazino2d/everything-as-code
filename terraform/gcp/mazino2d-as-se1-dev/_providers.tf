terraform {
  required_version = "~> 1.14"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.19"
    }
  }

  backend "gcs" {
    bucket = "mazino2d-as-se1-eac-tfstate"
    prefix = "state/gcp/mazino2d-as-se1-dev"
  }
}

locals {
  project_id         = "mazino2d-as-se1-dev"
  region             = "asia-southeast1"
  billing_account_id = "0138D2-6EFA6E-34332E"
}

provider "google" {
  project = local.project_id
}
