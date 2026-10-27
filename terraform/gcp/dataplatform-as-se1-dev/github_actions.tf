# Keyless auth for mazino2d/data-platform's GitHub Actions: CI on same-repo PRs
# and the scheduled pipeline both run dlt and dbt against BigQuery, so any ref
# is allowed. Fork PRs get no OIDC token.
resource "google_iam_workload_identity_pool" "github" {
  project                   = module.project.project_id
  workload_identity_pool_id = "github"
  display_name              = "GitHub Actions"
}

resource "google_iam_workload_identity_pool_provider" "data_platform" {
  project                            = module.project.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.github.workload_identity_pool_id
  workload_identity_pool_provider_id = "data-platform"
  display_name                       = "mazino2d/data-platform"

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.repository" = "assertion.repository"
    "attribute.ref"        = "assertion.ref"
  }
  attribute_condition = "assertion.repository == 'mazino2d/data-platform'"

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

resource "google_service_account" "gha_data_platform" {
  project      = module.project.project_id
  account_id   = "gha-data-platform"
  display_name = "GitHub Actions data-platform"
}

resource "google_service_account_iam_member" "gha_data_platform_wif" {
  service_account_id = google_service_account.gha_data_platform.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/attribute.repository/mazino2d/data-platform"
}

# Run query jobs, and create and write the datasets dlt and dbt manage.
resource "google_project_iam_member" "gha_data_platform" {
  for_each = toset([
    "roles/bigquery.jobUser",
    "roles/bigquery.dataEditor",
    "roles/serviceusage.serviceUsageConsumer",
  ])

  project = module.project.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.gha_data_platform.email}"
}
