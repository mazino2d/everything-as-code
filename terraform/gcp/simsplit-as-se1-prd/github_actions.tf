# Keyless auth for mazino2d/sim-split's GitHub Actions: workflows on main deploy
# Firestore rules, indexes and Hosting, and workflows on main or vX.Y.Z tags upload
# Android App Bundles to Google Play.
resource "google_iam_workload_identity_pool" "github" {
  project                   = module.project.project_id
  workload_identity_pool_id = "github"
  display_name              = "GitHub Actions"
}

resource "google_iam_workload_identity_pool_provider" "sim_split" {
  project                            = module.project.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.github.workload_identity_pool_id
  workload_identity_pool_provider_id = "sim-split"
  display_name                       = "mazino2d/sim-split"

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.repository" = "assertion.repository"
    "attribute.ref"        = "assertion.ref"
  }
  attribute_condition = "assertion.repository == 'mazino2d/sim-split' && (assertion.ref == 'refs/heads/main' || assertion.ref.startsWith('refs/tags/v'))"

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

resource "google_service_account" "gha_firebase_deployer" {
  project      = module.project.project_id
  account_id   = "gha-firebase-deployer"
  display_name = "GitHub Actions sim-split Firebase deployer"
}

resource "google_service_account_iam_member" "gha_firebase_deployer_wif" {
  service_account_id = google_service_account.gha_firebase_deployer.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/attribute.repository/mazino2d/sim-split"
}

# What `firebase deploy --only firestore,hosting` needs.
resource "google_project_iam_member" "gha_firebase_deployer" {
  for_each = toset([
    "roles/firebase.viewer",
    "roles/firebaserules.admin",
    "roles/datastore.indexAdmin",
    "roles/firebasehosting.admin",
    "roles/serviceusage.serviceUsageConsumer",
  ])

  project = module.project.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.gha_firebase_deployer.email}"
}

# Uploads AABs from .github/workflows/build_android.yml (manual runs on main and
# vX.Y.Z tags via release.yml). Needs no GCP roles: its rights come from being
# invited as a user in Play Console (Users and permissions), which has no
# Terraform/API support.
resource "google_service_account" "gha_play_publisher" {
  project      = module.project.project_id
  account_id   = "gha-play-publisher"
  display_name = "GitHub Actions sim-split Play publisher"
}

resource "google_service_account_iam_member" "gha_play_publisher_wif" {
  service_account_id = google_service_account.gha_play_publisher.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/attribute.repository/mazino2d/sim-split"
}
