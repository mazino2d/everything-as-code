module "vm" {
  source           = "./_modules/gcp-vm"
  name             = "vm"
  project_id       = module.project.project_id
  zone             = "asia-southeast1-b"
  machine_type     = "e2-small"
  spot             = true
  enable_static_ip = true
  enable_internet  = true
  extra_ports       = ["6443", "80", "443"]
  ssh_public_key   = var.ssh_public_key
  startup_script    = file("${path.module}/_scripts/install_k3s.sh")
}
