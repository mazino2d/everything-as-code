terraform {
  required_version = "~> 1.14"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.19"
    }
  }

  # This stack's state lives in the bucket it manages (tfstate.tf).
  backend "gcs" {
    bucket = "mazino2d-as-se1-eac-tfstate"
    prefix = "state/gcp/mazino2d-as-se1-eac"
  }
}

locals {
  project_id         = "mazino2d-as-se1-eac"
  billing_account_id = "0138D2-6EFA6E-34332E"
}

# Billing Budgets bill API quota to the caller's project, so every request is
# attributed to this project explicitly.
provider "google" {
  project               = local.project_id
  user_project_override = true
  billing_project       = local.project_id
}
