module "vm-dev" {
  source           = "./_modules/gcp-vm-k3s"
  name             = "vm-dev"
  project_id       = module.project.project_id
  zone             = "asia-southeast1-b"
  machine_type     = "e2-medium"
  disk_size_gb     = 20
  spot             = true
  external_ip_type = "ephemeral"
  duckdns_domain   = "mazino2d-k3s"
  extra_ports      = ["6443", "80", "443", "30379"]
  tags             = ["k8s", "dev"]
  ssh_public_key   = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHqUrfB0oPmolyXRYtA9kHDWYy5D2GhhaGb9odfQYvAu"
}
