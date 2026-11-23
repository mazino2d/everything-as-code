module "project" {
  source             = "./_modules/gcp-project"
  project_id         = local.project_id
  billing_account_id = local.billing_account_id
  services = [
    "iam.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com",
    "storage.googleapis.com",
    "monitoring.googleapis.com",
    # Workload Identity Federation for GitHub Actions (k8s-power.yml)
    "sts.googleapis.com",
    "iamcredentials.googleapis.com",
    # Budget alerts (budget.tf)
    "cloudbilling.googleapis.com",
    "billingbudgets.googleapis.com",
    # Gemini Cloud Assist (console chat): required APIs
    "geminicloudassist.googleapis.com",
    "cloudaicompanion.googleapis.com",
    "designcenter.googleapis.com",
    "cloudasset.googleapis.com",
    "appoptimize.googleapis.com",
    "apphub.googleapis.com",
    # Gemini Cloud Assist: recommended APIs for fuller answers
    "apptopology.googleapis.com",
    "recommender.googleapis.com",
  ]
}
