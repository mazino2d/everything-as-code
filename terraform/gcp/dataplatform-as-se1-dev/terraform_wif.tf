# everything-as-code's GitHub Actions (pull request plans and main applies) sign
# in as this project's terraform service account through the workload identity
# pool in mazino2d-as-se1-dev (terraform/gcp/mazino2d-as-se1-dev/tfstate.tf).
locals {
  eac_github_pool = "projects/238020767329/locations/global/workloadIdentityPools/github"
}

resource "google_service_account_iam_member" "terraform_wif" {
  service_account_id = "projects/${local.project_id}/serviceAccounts/terraform@${local.project_id}.iam.gserviceaccount.com"
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${local.eac_github_pool}/attribute.repository/mazino2d/everything-as-code"
}

import {
  to = google_service_account_iam_member.terraform_wif
  id = "projects/dataplatform-as-se1-dev/serviceAccounts/terraform@dataplatform-as-se1-dev.iam.gserviceaccount.com roles/iam.workloadIdentityUser principalSet://iam.googleapis.com/projects/238020767329/locations/global/workloadIdentityPools/github/attribute.repository/mazino2d/everything-as-code"
}
