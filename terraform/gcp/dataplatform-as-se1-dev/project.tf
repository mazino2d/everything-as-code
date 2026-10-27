module "project" {
  source             = "./_modules/gcp-project"
  name               = "dataplatform-as-se1-dev"
  project_id         = local.project_id
  billing_account_id = local.billing_account_id
  services = [
    "iam.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "serviceusage.googleapis.com",
    # Workload Identity Federation for data-platform's GitHub Actions (github_actions.tf)
    "sts.googleapis.com",
    "iamcredentials.googleapis.com",
    # Warehouse: dlt loads (real and fake), dbt models, Evidence reads
    "bigquery.googleapis.com",
    "bigquerystorage.googleapis.com",
    # Budget alerts and the billing kill switch (budget.tf, kill_switch.tf)
    "cloudbilling.googleapis.com",
    "billingbudgets.googleapis.com",
    "pubsub.googleapis.com",
    "cloudfunctions.googleapis.com",
    "run.googleapis.com",
    "cloudbuild.googleapis.com",
    "artifactregistry.googleapis.com",
    "eventarc.googleapis.com",
    "storage.googleapis.com",
    "logging.googleapis.com",
  ]
}
