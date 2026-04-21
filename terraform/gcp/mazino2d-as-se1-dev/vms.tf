module "vm" {
  source         = "./_modules/gcp-vm"
  name           = "vm"
  project_id     = module.project.project_id
  zone           = "us-central1-a"
  machine_type   = "e2-micro"
  ssh_public_key = var.ssh_public_key
  extra_ports    = ["6443", "80", "443"]
  startup_script = file("${path.module}/_scripts/install_k3s.sh")
}
