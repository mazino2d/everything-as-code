# Keyless auth for GitHub Actions: only workflows on main of this repository can impersonate
# the service accounts below.
resource "google_iam_workload_identity_pool" "github" {
  project                   = module.project.project_id
  workload_identity_pool_id = "github"
  display_name              = "GitHub Actions"

  # Needs sts/iamcredentials APIs enabled by module.project.
  depends_on = [module.project]
}

resource "google_iam_workload_identity_pool_provider" "github" {
  project                            = module.project.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.github.workload_identity_pool_id
  workload_identity_pool_provider_id = "everything-as-code"
  display_name                       = "mazino2d/everything-as-code"

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.repository" = "assertion.repository"
    "attribute.ref"        = "assertion.ref"
  }
  attribute_condition = "assertion.repository == 'mazino2d/everything-as-code' && assertion.ref == 'refs/heads/main'"

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

# Used by .github/workflows/k8s-power.yml to scale cluster workloads to zero and back.
resource "google_service_account" "gha_k8s_power" {
  project      = module.project.project_id
  account_id   = "gha-k8s-power"
  display_name = "GitHub Actions k8s-power workflow"
}

resource "google_service_account_iam_member" "gha_k8s_power_wif" {
  service_account_id = google_service_account.gha_k8s_power.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/attribute.repository/mazino2d/everything-as-code"
}

resource "google_project_iam_member" "gha_k8s_power_container_developer" {
  project = module.project.project_id
  role    = "roles/container.developer"
  member  = "serviceAccount:${google_service_account.gha_k8s_power.email}"
}
