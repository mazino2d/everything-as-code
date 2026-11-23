# everything-as-code's GitHub Actions sign in through the workload identity
# pool in mazino2d-as-se1-eac (terraform/gcp/mazino2d-as-se1-eac/github_actions.tf):
# main applies as this project's terraform service account, pull request plans
# as terraform-plan, which can read the project but not change it.
locals {
  eac_github_pool = "projects/725985974531/locations/global/workloadIdentityPools/github"
  eac_repository  = "principalSet://iam.googleapis.com/${local.eac_github_pool}/attribute.repository/mazino2d/everything-as-code"

  terraform_plan_roles = toset([
    "roles/viewer",
    "roles/iam.securityReviewer",
    "roles/serviceusage.apiKeysViewer",
    "roles/serviceusage.serviceUsageConsumer",
    "roles/storage.objectViewer",
  ])
}

resource "google_service_account_iam_member" "terraform_wif" {
  service_account_id = "projects/${local.project_id}/serviceAccounts/terraform@${local.project_id}.iam.gserviceaccount.com"
  role               = "roles/iam.workloadIdentityUser"
  member             = local.eac_repository
}

resource "google_service_account" "terraform_plan" {
  project      = module.project.project_id
  account_id   = "terraform-plan"
  display_name = "Terraform plan (everything-as-code CI)"
}

resource "google_project_iam_member" "terraform_plan" {
  for_each = local.terraform_plan_roles

  project = module.project.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.terraform_plan.email}"
}

resource "google_service_account_iam_member" "terraform_plan_wif" {
  service_account_id = google_service_account.terraform_plan.name
  role               = "roles/iam.workloadIdentityUser"
  member             = local.eac_repository
}
