# Keyless auth for everything-as-code's Terraform workflow: main applies sign in
# as the terraform service account of the project a stack manages, pull request
# plans as that project's read-only terraform-plan service account. Each of
# those projects creates and binds them in its own terraform_wif.tf; this
# project's are below.
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

locals {
  eac_repository = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/attribute.repository/mazino2d/everything-as-code"
  # The provider only admits mazino2d/everything-as-code, so this is its main branch.
  eac_main = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/attribute.ref/refs/heads/main"
}

# Runs the stacks outside GCP (github, cloudflare, infisical, grafana) and
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
  member             = local.eac_main
}

# Plans those stacks: reads this project, the state bucket (tfstate.tf) and the
# billing accounts (billing_iam.tf), but changes nothing.
resource "google_service_account" "terraform_plan" {
  project      = module.project.project_id
  account_id   = "terraform-plan"
  display_name = "Terraform plan (everything-as-code CI)"
}

resource "google_project_iam_member" "terraform_plan" {
  for_each = toset([
    "roles/viewer",
    "roles/iam.securityReviewer",
    "roles/serviceusage.serviceUsageConsumer",
  ])

  project = module.project.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.terraform_plan.email}"
}

resource "google_service_account_iam_member" "terraform_plan_wif" {
  service_account_id = google_service_account.terraform_plan.name
  role               = "roles/iam.workloadIdentityUser"
  member             = local.eac_repository
}
