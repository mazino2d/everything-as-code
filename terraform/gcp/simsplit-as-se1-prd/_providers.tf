terraform {
  required_version = "~> 1.14"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.19"
    }
    # Firebase resources (project, apps, Hosting) are only in google-beta
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 7.19"
    }
    # Zips the billing kill switch function source (kill_switch.tf)
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.7"
    }
  }

  backend "gcs" {
    bucket = "mazino2d-as-se1-dev-tfstate"
    prefix = "state/gcp/simsplit-as-se1-prd"
  }
}

locals {
  project_id         = "simsplit-as-se1-prd"
  region             = "asia-southeast1"
  billing_account_id = "014412-F60C67-E5B80D"
  alert_email        = "mazino2d@gmail.com"
}

# Firebase, Identity Platform and Billing Budgets bill API quota to the caller's
# project, so every request is attributed to this project explicitly.
provider "google" {
  project               = local.project_id
  user_project_override = true
  billing_project       = local.project_id
}

provider "google-beta" {
  project               = local.project_id
  user_project_override = true
  billing_project       = local.project_id
}
