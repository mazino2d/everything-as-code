terraform {
  required_version = "~> 1.14"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.19"
    }
  }

  backend "gcs" {
    bucket = "mazino2d-as-se1-dev-tfstate"
    prefix = "state/gcp/mazino2d-as-se1-dev"
  }
}

provider "google" {
  project = "mazino2d-as-se1-dev"
}

