terraform {
  required_version = "~> 1.14"

  required_providers {
    google = {
      source  = "hashicorp/google"
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
    prefix = "state/gcp/dataplatform-as-se1-dev"
  }
}

locals {
  project_id         = "dataplatform-as-se1-dev"
  region             = "asia-southeast1"
  billing_account_id = "016BA1-3DBFBB-1B7972"
}

# Billing Budgets bill API quota to the caller's project, so every request is
# attributed to this project explicitly.
provider "google" {
  project               = local.project_id
  user_project_override = true
  billing_project       = local.project_id
}
