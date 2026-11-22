# Terraform state and per-stack variables for every everything-as-code stack:
#   state/<stack path under terraform/>/default.tfstate  (gcs backend, locked)
#   secrets/<stack path under terraform/>.tfvars.json    (copied in by CI and make)
# Bootstrapped by hand with gcloud (see _docs/setup.md) and adopted below.
locals {
  # Every stack's CI identity: the `terraform` service account of the project it
  # manages, or this project's one for stacks outside GCP.
  terraform_service_accounts = toset([
    for project in [
      "mazino2d-as-se1-dev",
      "simsplit-as-se1-dev",
      "simsplit-as-se1-prd",
      "dataplatform-as-se1-dev",
      "dataplatform-as-se1-prd",
    ] : "terraform@${project}.iam.gserviceaccount.com"
  ])
}

resource "google_storage_bucket" "tfstate" {
  name                        = "mazino2d-as-se1-dev-tfstate"
  project                     = module.project.project_id
  location                    = "ASIA-SOUTHEAST1"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  force_destroy               = false

  versioning {
    enabled = true
  }

  # Keep the 30 most recent superseded versions of each object.
  lifecycle_rule {
    action {
      type = "Delete"
    }

    condition {
      with_state         = "ARCHIVED"
      num_newer_versions = 30
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_storage_bucket_iam_member" "tfstate" {
  for_each = local.terraform_service_accounts

  bucket = google_storage_bucket.tfstate.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${each.value}"
}

# Workflows of this repository (pull request plans and main applies) sign in as
# this project's terraform service account; the other projects grant theirs in
# their own stacks (terraform_wif.tf).
resource "google_service_account_iam_member" "terraform_wif" {
  service_account_id = "projects/${module.project.project_id}/serviceAccounts/terraform@${module.project.project_id}.iam.gserviceaccount.com"
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/attribute.repository/mazino2d/everything-as-code"
}

# Who read or changed state and stack variables.
resource "google_project_iam_audit_config" "storage" {
  project = module.project.project_id
  service = "storage.googleapis.com"

  audit_log_config {
    log_type = "DATA_READ"
  }

  audit_log_config {
    log_type = "DATA_WRITE"
  }
}

import {
  to = google_storage_bucket.tfstate
  id = "mazino2d-as-se1-dev-tfstate"
}

import {
  for_each = local.terraform_service_accounts
  to       = google_storage_bucket_iam_member.tfstate[each.value]
  id       = "b/mazino2d-as-se1-dev-tfstate roles/storage.objectAdmin serviceAccount:${each.value}"
}

import {
  to = google_service_account_iam_member.terraform_wif
  id = "projects/mazino2d-as-se1-dev/serviceAccounts/terraform@mazino2d-as-se1-dev.iam.gserviceaccount.com roles/iam.workloadIdentityUser principalSet://iam.googleapis.com/projects/238020767329/locations/global/workloadIdentityPools/github/attribute.repository/mazino2d/everything-as-code"
}
