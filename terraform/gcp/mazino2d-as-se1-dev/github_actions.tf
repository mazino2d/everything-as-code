# Keyless auth for this repository's GitHub Actions. Any workflow of the repository
# gets a token (pull request plans need one); each service account decides which
# refs may impersonate it.
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
  attribute_condition = "assertion.repository == 'mazino2d/everything-as-code'"

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

# Only workflows running on main.
resource "google_service_account_iam_member" "gha_k8s_power_wif" {
  service_account_id = google_service_account.gha_k8s_power.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principal://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/subject/repo:mazino2d/everything-as-code:ref:refs/heads/main"
}

resource "google_project_iam_member" "gha_k8s_power_container_developer" {
  project = module.project.project_id
  role    = "roles/container.developer"
  member  = "serviceAccount:${google_service_account.gha_k8s_power.email}"
}
