# Backend for SimSplit's co-worked groups (mazino2d/sim-split, R-3). Firestore
# rules, indexes and Hosting content live in the sim-split repo and are deployed
# from its CI with the gha-firebase-deployer identity (github_actions.tf).
resource "google_firebase_project" "this" {
  provider = google-beta
  project  = module.project.project_id
}

# Only the (default) database gets the Firestore free quota.
resource "google_firestore_database" "default" {
  project                           = google_firebase_project.this.project
  name                              = "(default)"
  location_id                       = local.region
  type                              = "FIRESTORE_NATIVE"
  concurrency_mode                  = "OPTIMISTIC"
  app_engine_integration_mode       = "DISABLED"
  point_in_time_recovery_enablement = "POINT_IN_TIME_RECOVERY_DISABLED"
  delete_protection_state           = "DELETE_PROTECTION_ENABLED"
}

locals {
  # Signing certificate fingerprints for Google sign-in on Android: the upload
  # key (android/app/simsplit.jks in sim-split) and the Play App Signing key
  # (Play Console → Test and release → App integrity).
  android_sha1_hashes   = []
  android_sha256_hashes = []
}

resource "google_firebase_android_app" "sim_split" {
  provider        = google-beta
  project         = google_firebase_project.this.project
  display_name    = "SimSplit Android"
  package_name    = "com.mazino2d.simsplit"
  sha1_hashes     = local.android_sha1_hashes
  sha256_hashes   = local.android_sha256_hashes
  deletion_policy = "DELETE"
}

resource "google_firebase_apple_app" "sim_split" {
  provider        = google-beta
  project         = google_firebase_project.this.project
  display_name    = "SimSplit iOS"
  bundle_id       = "com.mazino2d.simsplit"
  team_id         = var.apple_team_id
  deletion_policy = "DELETE"
}

# Serves the invite join page plus assetlinks.json / apple-app-site-association
# for App Links and Universal Links.
resource "google_firebase_hosting_site" "default" {
  provider = google-beta
  project  = google_firebase_project.this.project
  site_id  = "simsplit"
}
