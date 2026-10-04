# Sign-in is Google or Apple only: no email/password, phone or anonymous users.
resource "google_identity_platform_config" "this" {
  project                    = google_firebase_project.this.project
  autodelete_anonymous_users = true

  sign_in {
    allow_duplicate_emails = false

    anonymous {
      enabled = false
    }

    email {
      enabled = false
    }
  }

  authorized_domains = [
    "localhost",
    "${local.project_id}.firebaseapp.com",
    "${google_firebase_hosting_site.default.site_id}.web.app",
  ]
}

resource "google_identity_platform_default_supported_idp_config" "google" {
  count = var.google_oauth_client_id == null ? 0 : 1

  project       = google_firebase_project.this.project
  idp_id        = "google.com"
  client_id     = var.google_oauth_client_id
  client_secret = var.google_oauth_client_secret
  enabled       = true

  depends_on = [google_identity_platform_config.this]
}

resource "google_identity_platform_default_supported_idp_config" "apple" {
  count = var.apple_services_id == null ? 0 : 1

  project       = google_firebase_project.this.project
  idp_id        = "apple.com"
  client_id     = var.apple_services_id
  client_secret = var.apple_client_secret
  enabled       = true

  depends_on = [google_identity_platform_config.this]
}
