moved {
  from = google_storage_bucket.free_tier
  to   = google_storage_bucket.velero_backups
}

# Velero backups (kubernetes/clusters/mazino2d-as-se1-dev); US-CENTRAL1 for the
# always-free tier.
resource "google_storage_bucket" "velero_backups" {
  name                        = "mazino2d-as-se1-dev-velero-backups-usc1"
  project                     = module.project.project_id
  location                    = "US-CENTRAL1"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  force_destroy               = false

  versioning {
    enabled = false
  }

  lifecycle_rule {
    action {
      type = "Delete"
    }

    condition {
      age = 30
    }
  }

  labels = {
    managed_by = "terraform"
    tier       = "always-free"
    env        = "dev"
  }
}
