# Bootstrapped by hand with gcloud (_docs/setup.md); the first apply adopts it.
import {
  to = module.project.google_project.this
  id = local.project_id
}

import {
  to = google_storage_bucket.tfstate
  id = "mazino2d-as-se1-eac-tfstate"
}

import {
  for_each = local.terraform_service_accounts
  to       = google_storage_bucket_iam_member.tfstate[each.value]
  id       = "b/mazino2d-as-se1-eac-tfstate roles/storage.objectAdmin serviceAccount:${each.value}"
}

import {
  to = google_iam_workload_identity_pool.github
  id = "projects/mazino2d-as-se1-eac/locations/global/workloadIdentityPools/github"
}

import {
  to = google_iam_workload_identity_pool_provider.everything_as_code
  id = "projects/mazino2d-as-se1-eac/locations/global/workloadIdentityPools/github/providers/everything-as-code"
}

import {
  to = google_service_account.terraform
  id = "projects/mazino2d-as-se1-eac/serviceAccounts/terraform@mazino2d-as-se1-eac.iam.gserviceaccount.com"
}

import {
  to = google_project_iam_member.terraform_owner
  id = "mazino2d-as-se1-eac roles/owner serviceAccount:terraform@mazino2d-as-se1-eac.iam.gserviceaccount.com"
}

import {
  to = google_service_account_iam_member.terraform_wif
  id = "projects/mazino2d-as-se1-eac/serviceAccounts/terraform@mazino2d-as-se1-eac.iam.gserviceaccount.com roles/iam.workloadIdentityUser principalSet://iam.googleapis.com/projects/725985974531/locations/global/workloadIdentityPools/github/attribute.repository/mazino2d/everything-as-code"
}
