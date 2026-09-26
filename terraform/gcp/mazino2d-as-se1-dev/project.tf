module "project" {
  source             = "./_modules/gcp-project"
  name               = "mazino2d-as-se1-dev"
  project_id         = "mazino2d-as-se1-dev"
  billing_account_id = "0138D2-6EFA6E-34332E"
  services = [
    "iam.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com",
    "storage.googleapis.com",
    "monitoring.googleapis.com",
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
