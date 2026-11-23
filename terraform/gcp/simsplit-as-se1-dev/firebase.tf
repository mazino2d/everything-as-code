# Dev backend for SimSplit (mazino2d/sim-split): internal-test Android builds
# (com.mazino2d.simsplit.dev) and the web build on simsplit-as-se1-dev.web.app talk to
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

locals {
  # Signing certificate fingerprints of the Play app com.mazino2d.simsplit.dev,
  # for Google sign-in on Android: Play Console → SimSplit Dev → Protected with
  # Play → Play app signing. The upload key is prd's (same keystore).
  android_sha1_hashes = [
    "10be3b075201a9ed36d6f4da5a2e7f0629ccb21f", # Play App Signing
    "d4ba311c4d85f5f084b06839742de9390e237fa5", # upload key
  ]
  android_sha256_hashes = [
    "d152d8bb3d79afd6303ef2eee6147a3ec8ee7186b015b2fd7d14919fc7f7c7b1", # Play App Signing
    "8ab3bf0adce70fdd609fb0d527eed930b6f829b2f69af45cdcd179b885a89399", # upload key
  ]
}

# A separate Play app, so internal-test builds install next to the production
# app.
resource "google_firebase_android_app" "sim_split" {
  provider        = google-beta
  project         = google_firebase_project.this.project
  display_name    = "SimSplit Dev"
  package_name    = "com.mazino2d.simsplit.dev"
  sha1_hashes     = local.android_sha1_hashes
  sha256_hashes   = local.android_sha256_hashes
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

# The dev web build and assetlinks.json for App Links on the dev app are served
# from the project's default Hosting site, which Firebase creates with the
# project ID as its name. Site names are global and "simsplit-dev" is taken by
# another project.
locals {
  hosting_site_id = local.project_id
}
