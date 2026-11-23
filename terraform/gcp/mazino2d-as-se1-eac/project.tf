# Holds what every everything-as-code stack needs before it can run: the
# Terraform state bucket and the identity GitHub Actions signs in with.
module "project" {
  source             = "./_modules/gcp-project"
  project_id         = local.project_id
  billing_account_id = local.billing_account_id
  services = [
    "iam.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "serviceusage.googleapis.com",
    # Workload Identity Federation for GitHub Actions (github_actions.tf)
    "sts.googleapis.com",
    "iamcredentials.googleapis.com",
    # State bucket (tfstate.tf) and its audit logs
    "storage.googleapis.com",
    "logging.googleapis.com",
    # Budget alert (budget.tf)
    "cloudbilling.googleapis.com",
    "billingbudgets.googleapis.com",
  ]
}

# Deleting this project would lose every stack's state.
resource "google_resource_manager_lien" "no_delete" {
  parent       = "projects/${module.project.project_number}"
  restrictions = ["resourcemanager.projects.delete"]
  origin       = "everything-as-code"
  reason       = "Holds the Terraform state of every everything-as-code stack"
}
