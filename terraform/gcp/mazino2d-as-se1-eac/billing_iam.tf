# Who may use each billing account. A project's terraform service account needs
# Billing Account User to link its project and Billing Account Costs Manager to
# manage its budget (budget.tf in each GCP stack); its terraform-plan service
# account gets Billing Account Viewer to read them. This stack's own service
# account holds Billing Account Administrator so it can grant these; that one
# binding was made by hand once, since nothing else can grant it.
locals {
  billing_accounts = {
    mazino2d      = local.billing_account_id
    sim_split     = "014412-F60C67-E5B80D"
    data_platform = "016BA1-3DBFBB-1B7972"
  }

  # Billing account => projects whose terraform service account uses it.
  billing_account_projects = {
    mazino2d      = ["mazino2d-as-se1-eac", "mazino2d-as-se1-dev"]
    sim_split     = ["simsplit-as-se1-dev", "simsplit-as-se1-prd"]
    data_platform = ["dataplatform-as-se1-dev", "dataplatform-as-se1-prd"]
  }

  billing_account_members = {
    for item in flatten([
      for account, projects in local.billing_account_projects : [
        for pair in setproduct(projects, ["roles/billing.user", "roles/billing.costsManager"]) : {
          account = account
          project = pair[0]
          role    = pair[1]
        }
      ]
    ]) : "${item.account}/${item.project}/${item.role}" => item
  }
}

resource "google_billing_account_iam_member" "terraform" {
  for_each = local.billing_account_members

  billing_account_id = local.billing_accounts[each.value.account]
  role               = each.value.role
  member             = "serviceAccount:terraform@${each.value.project}.iam.gserviceaccount.com"
}

resource "google_billing_account_iam_member" "eac_admin" {
  for_each = local.billing_accounts

  billing_account_id = each.value
  role               = "roles/billing.admin"
  member             = "serviceAccount:${google_service_account.terraform.email}"
}

resource "google_billing_account_iam_member" "terraform_plan" {
  for_each = {
    for pair in flatten([
      for account, projects in local.billing_account_projects : [
        for project in projects : { account = account, project = project }
      ]
    ]) : "${pair.account}/${pair.project}" => pair
  }

  billing_account_id = local.billing_accounts[each.value.account]
  role               = "roles/billing.viewer"
  member             = "serviceAccount:terraform-plan@${each.value.project}.iam.gserviceaccount.com"
}

# This stack's plans read the IAM policy of every billing account above;
# terraform_plan already covers the account this project is on.
resource "google_billing_account_iam_member" "eac_plan" {
  for_each = {
    for account, id in local.billing_accounts : account => id
    if !contains(local.billing_account_projects[account], module.project.project_id)
  }

  billing_account_id = each.value
  role               = "roles/billing.viewer"
  member             = "serviceAccount:${google_service_account.terraform_plan.email}"
}
