# Terraform state and per-stack variables for every everything-as-code stack:
#   state/<stack path under terraform/>/default.tfstate  (gcs backend, locked)
#   secrets/<stack path under terraform/>.tfvars.json    (copied in by CI and make)
locals {
  # Projects whose terraform (apply) and terraform-plan service accounts run
  # the stacks; billing_iam.tf grants them their billing roles too.
  terraform_projects = [
    "mazino2d-as-se1-eac",
    "mazino2d-as-se1-dev",
    "simsplit-as-se1-dev",
    "simsplit-as-se1-prd",
    "dataplatform-as-se1-dev",
    "dataplatform-as-se1-prd",
  ]

  terraform_service_accounts      = toset([for project in local.terraform_projects : "terraform@${project}.iam.gserviceaccount.com"])
  terraform_plan_service_accounts = toset([for project in local.terraform_projects : "terraform-plan@${project}.iam.gserviceaccount.com"])
}

resource "google_storage_bucket" "tfstate" {
  name                        = "mazino2d-as-se1-eac-tfstate"
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

# Plans read state and stack variables but never write them (they run without
# the state lock).
resource "google_storage_bucket_iam_member" "tfstate_plan" {
  for_each = local.terraform_plan_service_accounts

  bucket = google_storage_bucket.tfstate.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${each.value}"
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
