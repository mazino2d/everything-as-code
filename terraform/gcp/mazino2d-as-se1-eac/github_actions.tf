# Keyless auth for everything-as-code's Terraform workflow: pull request plans
# and main applies sign in as the terraform service account of the project a
# stack manages. Each of those projects grants the binding in its own
# terraform_wif.tf; this one is below.
resource "google_iam_workload_identity_pool" "github" {
  project                   = module.project.project_id
  workload_identity_pool_id = "github"
  display_name              = "GitHub Actions"
}

resource "google_iam_workload_identity_pool_provider" "everything_as_code" {
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

# Runs the stacks outside GCP (github, cloudflare, infisical, grafana, k8s) and
# this one.
resource "google_service_account" "terraform" {
  project      = module.project.project_id
  account_id   = "terraform"
  display_name = "Terraform (everything-as-code CI)"
}

resource "google_project_iam_member" "terraform_owner" {
  project = module.project.project_id
  role    = "roles/owner"
  member  = "serviceAccount:${google_service_account.terraform.email}"
}

resource "google_service_account_iam_member" "terraform_wif" {
  service_account_id = google_service_account.terraform.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/attribute.repository/mazino2d/everything-as-code"
}
