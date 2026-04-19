module "project" {
  source             = "./_modules/gcp-project"
  name               = "mazino2d-as-se1-dev"
  project_id         = "mazino2d-as-se1-dev"
  billing_account_id = "016BA1-3DBFBB-1B7972"
  services           = ["compute.googleapis.com", "iam.googleapis.com", "cloudresourcemanager.googleapis.com"]
}

# ===================================================================
# Compute
# ===================================================================

module "vm" {
  source         = "./_modules/gcp-vm"
  name           = "vm"
  project_id     = module.project.project_id
  zone           = "us-central1-a"
  machine_type   = "e2-micro"
  ssh_public_key = var.ssh_public_key
}
