module "project" {
  source             = "./_modules/gcp-project"
  name               = "mazino2d-as-se1-dev"
  project_id         = "mazino2d-as-se1-dev"
  billing_account_id = "016BA1-3DBFBB-1B7972"
  services = [
    "iam.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com",
    "storage.googleapis.com",
    "monitoring.googleapis.com",
  ]
}
