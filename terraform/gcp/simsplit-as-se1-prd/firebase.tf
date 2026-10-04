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
  # Signing certificate fingerprints for Google sign-in on Android: the Play App
  # Signing key and the upload key (Play Console → Protected with Play → Play app
  # signing). Builds come from CI only, so no debug key is registered.
  android_sha1_hashes = [
    "05d73ddbafe5b6beeb2c11e0f29714e6dd901eb3", # Play App Signing
    "d4ba311c4d85f5f084b06839742de9390e237fa5", # upload key
  ]
  android_sha256_hashes = [
    "b63a2edcede31111bc5eb43e31f7c08636fe4e55ad9b3fa089564ecc65450e4f", # Play App Signing
    "8ab3bf0adce70fdd609fb0d527eed930b6f829b2f69af45cdcd179b885a89399", # upload key
  ]
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
