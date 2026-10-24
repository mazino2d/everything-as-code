# Dev backend for SimSplit (mazino2d/sim-split): internal-test Android builds
# (com.mazino2d.simsplit.dev) and the web build on simsplit-dev.web.app talk to
# this project, never to simsplit-as-se1-prd. Firestore rules, indexes and
# Hosting content live in the sim-split repo and are deployed from its CI with
# the gha-firebase-deployer identity (github_actions.tf).
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

# A separate Play app, so internal-test builds install next to the production
# app. Its fingerprints are variables until Play Console has created its app
# signing key (_variables.tf).
resource "google_firebase_android_app" "sim_split" {
  provider        = google-beta
  project         = google_firebase_project.this.project
  display_name    = "SimSplit Dev"
  package_name    = "com.mazino2d.simsplit.dev"
  sha1_hashes     = var.android_sha1_hashes
  sha256_hashes   = var.android_sha256_hashes
  deletion_policy = "DELETE"
}

# Signs in with a popup through <project>.firebaseapp.com, which the Web OAuth
# client allows (_docs/setup.md § 2).
resource "google_firebase_web_app" "sim_split" {
  provider        = google-beta
  project         = google_firebase_project.this.project
  display_name    = "SimSplit Dev Web"
  deletion_policy = "DELETE"
}

data "google_firebase_web_app_config" "sim_split" {
  provider   = google-beta
  project    = google_firebase_project.this.project
  web_app_id = google_firebase_web_app.sim_split.app_id
}

# Serves the dev web build plus assetlinks.json for App Links on the dev app.
resource "google_firebase_hosting_site" "default" {
  provider = google-beta
  project  = google_firebase_project.this.project
  site_id  = "simsplit-dev"
}
