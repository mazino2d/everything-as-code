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

  cloud {
    organization = "mazino2d-everything-as-code"

    workspaces {
      name = "gcp-dataplatform-as-se1-prd"
    }
  }
}

locals {
  project_id         = "dataplatform-as-se1-prd"
  region             = "asia-southeast1"
  billing_account_id = "0138D2-6EFA6E-34332E"
}

# Billing Budgets bill API quota to the caller's project, so every request is
# attributed to this project explicitly.
provider "google" {
  credentials           = var.gcp_credentials
  project               = local.project_id
  user_project_override = true
  billing_project       = local.project_id
}
