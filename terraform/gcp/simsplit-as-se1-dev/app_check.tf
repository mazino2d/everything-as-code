# Firebase App Check, as in simsplit-as-se1-prd: Auth and Firestore accept only
# requests that carry a token from the genuine app, so the public Firebase
# config cannot be used to run up the bill and trip the kill switch.

# Android: Play Integrity verdicts, through the project linked in Play Console
# for SimSplit Dev (_docs/setup.md § 3). Default token TTL (1 h).
resource "google_firebase_app_check_play_integrity_config" "android" {
  provider = google-beta
  project  = google_firebase_project.this.project
  app_id   = google_firebase_android_app.sim_split.app_id
}

# Web: a score-based reCAPTCHA key for the dev Hosting site. Every token
# exchange is one assessment, and only 10,000 a month are free; a 24 h token
# TTL keeps that far away.
resource "google_recaptcha_enterprise_key" "web" {
  provider     = google-beta
  project      = google_firebase_project.this.project
  display_name = "SimSplit Dev Web App Check"

  web_settings {
    integration_type  = "SCORE"
    allow_all_domains = false
    allowed_domains = [
      "${local.hosting_site_id}.web.app",
      "${local.project_id}.firebaseapp.com",
      "localhost",
    ]
  }
}

resource "google_firebase_app_check_recaptcha_enterprise_config" "web" {
  provider  = google-beta
  project   = google_firebase_project.this.project
  app_id    = google_firebase_web_app.sim_split.app_id
  site_key  = google_recaptcha_enterprise_key.web.name
  token_ttl = "86400s"
}

# Debug builds (developer machines) send this token instead of an attestation.
# The app reads the same value from --dart-define=APP_CHECK_DEBUG_TOKEN.
resource "google_firebase_app_check_debug_token" "android" {
  count        = var.app_check_debug_token != null ? 1 : 0
  provider     = google-beta
  project      = google_firebase_project.this.project
  app_id       = google_firebase_android_app.sim_split.app_id
  display_name = "Developer"
  token        = var.app_check_debug_token
}

resource "google_firebase_app_check_debug_token" "web" {
  count        = var.app_check_debug_token != null ? 1 : 0
  provider     = google-beta
  project      = google_firebase_project.this.project
  app_id       = google_firebase_web_app.sim_split.app_id
  display_name = "Developer"
  token        = var.app_check_debug_token
}

# Enforced from the start, like prd, so dev catches App Check problems before
# a release does. Debug builds need the debug token. Set
# app_check_enforced = false to fall back to metrics only.
resource "google_firebase_app_check_service_config" "this" {
  for_each         = toset(["firestore.googleapis.com", "identitytoolkit.googleapis.com"])
  provider         = google-beta
  project          = google_firebase_project.this.project
  service_id       = each.key
  enforcement_mode = var.app_check_enforced ? "ENFORCED" : "UNENFORCED"

  # Firestore App Check fails with "Cloud Firestore is not yet set up" when it
  # runs before the database exists.
  depends_on = [google_firestore_database.default]
}
