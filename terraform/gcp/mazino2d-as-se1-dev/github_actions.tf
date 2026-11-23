# Used by .github/workflows/k8s-power.yml to scale cluster workloads to zero and back.
# The workflow signs in through the github pool in mazino2d-as-se1-eac (the same one
# Terraform CI uses, local.eac_github_pool in terraform_wif.tf); only runs on main may
# impersonate this service account.

resource "google_service_account" "gha_k8s_power" {
  project      = module.project.project_id
  account_id   = "gha-k8s-power"
  display_name = "GitHub Actions k8s-power workflow"
}

resource "google_service_account_iam_member" "gha_k8s_power_wif" {
  service_account_id = google_service_account.gha_k8s_power.name
  role               = "roles/iam.workloadIdentityUser"
  # The pool's provider already pins the repository to mazino2d/everything-as-code.
  member = local.eac_main
}

resource "google_project_iam_member" "gha_k8s_power_container_developer" {
  project = module.project.project_id
  role    = "roles/container.developer"
  member  = "serviceAccount:${google_service_account.gha_k8s_power.email}"
}
