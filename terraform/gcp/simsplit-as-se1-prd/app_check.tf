# Firebase App Check for sim-split (R-3 P9): Auth and Firestore accept only
# requests that carry a token from the genuine app, so the public Firebase
# config cannot be used to run up the bill and trip the kill switch.

# Android: Play Integrity verdicts, through the project linked in Play Console
# (_docs/setup.md § 6). Default token TTL (1 h); Play Integrity's free quota
# is far above what 100 users need.
resource "google_firebase_app_check_play_integrity_config" "android" {
  provider = google-beta
  project  = google_firebase_project.this.project
  app_id   = google_firebase_android_app.sim_split.app_id
}

# Web: a score-based reCAPTCHA key for the Hosting site. Every token exchange
# is one assessment, and only 10,000 a month are free; a 24 h token TTL keeps
# 100 daily web users at ~3,000 a month.
# No localhost: local web builds run against simsplit-as-se1-dev (APP_ENV=dev),
# so nothing built on a laptop can get prd tokens or write to the prd warehouse.
resource "google_recaptcha_enterprise_key" "web" {
  provider     = google-beta
  project      = google_firebase_project.this.project
  display_name = "SimSplit Web App Check"

  web_settings {
    integration_type  = "SCORE"
    allow_all_domains = false
    allowed_domains = [
      "${google_firebase_hosting_site.default.site_id}.web.app",
      "${google_firebase_hosting_site.default.site_id}.firebaseapp.com",
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

# No App Check debug tokens on prd: debug builds run against dev
# (simsplit-as-se1-dev, APP_ENV=dev), which registers its own (sim-split R-8 P1).

# Enforced: requests without a valid token are rejected. Every client sends
# App Check tokens (Android from v2.0.0, the web app since sim-split#45).
# Set app_check_enforced = false to fall back to metrics only.
resource "google_firebase_app_check_service_config" "this" {
  for_each         = toset(["firestore.googleapis.com", "identitytoolkit.googleapis.com"])
  provider         = google-beta
  project          = google_firebase_project.this.project
  service_id       = each.key
  enforcement_mode = var.app_check_enforced ? "ENFORCED" : "UNENFORCED"
}
