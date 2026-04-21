module "project" {
  source             = "./_modules/gcp-project"
  name               = "mazino2d-as-se1-dev"
  project_id         = "mazino2d-as-se1-dev"
  billing_account_id = "016BA1-3DBFBB-1B7972"
  services           = ["compute.googleapis.com", "iam.googleapis.com", "cloudresourcemanager.googleapis.com"]
}
